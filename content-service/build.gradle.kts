plugins {
    java
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

extra["springCloudVersion"] = rootProject.extra["springCloudVersion"]
extra["geminiVersion"] = rootProject.extra["geminiVersion"]

dependencies {
    // Spring Boot starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    
    // Spring Cloud
    implementation("org.springframework.cloud:spring-cloud-starter-netflix-eureka-client")
    
    // Database
    runtimeOnly("org.postgresql:postgresql")
    
    // Google Gemini AI
    implementation("com.google.genai:google-genai:${property("geminiVersion")}")
    
    // OpenAPI Documentation
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:${rootProject.extra["springdocVersion"]}")
    
    // MapStruct for DTO mapping
    implementation("org.mapstruct:mapstruct:${rootProject.extra["mapStructVersion"]}")
    annotationProcessor("org.mapstruct:mapstruct-processor:${rootProject.extra["mapStructVersion"]}")
    annotationProcessor("org.projectlombok:lombok-mapstruct-binding:0.2.0")
    
    // Annotation processor
    annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")
    
    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("com.h2database:h2")
    testImplementation("org.testcontainers:testcontainers:${rootProject.extra["testcontainersVersion"]}")
    testImplementation("org.testcontainers:postgresql:${rootProject.extra["testcontainersVersion"]}")
    testImplementation("org.testcontainers:junit-jupiter:${rootProject.extra["testcontainersVersion"]}")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:${property("springCloudVersion")}")
    }
}

tasks.bootJar {
    archiveBaseName.set("content-service")
    archiveVersion.set("")
    archiveClassifier.set("")
}

tasks.jar {
    enabled = false
}
