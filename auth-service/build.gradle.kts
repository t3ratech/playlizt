plugins {
    java
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

extra["springCloudVersion"] = rootProject.extra["springCloudVersion"]
extra["jjwtVersion"] = rootProject.extra["jjwtVersion"]

dependencies {
    // Spring Boot starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-security")
    
    // Spring Cloud
    implementation("org.springframework.cloud:spring-cloud-starter-netflix-eureka-client")
    
    // Database
    runtimeOnly("org.postgresql:postgresql")
    implementation("com.google.cloud:spring-cloud-gcp-starter-sql-postgresql")
    
    // JWT
    implementation("io.jsonwebtoken:jjwt-api:${property("jjwtVersion")}")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:${property("jjwtVersion")}")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:${property("jjwtVersion")}")
    
    // Argon2 password encoder (quantum-resistant)
    implementation("org.bouncycastle:bcprov-jdk18on:1.78")
    
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
    testImplementation("org.springframework.security:spring-security-test")
    testRuntimeOnly("com.h2database:h2")
    testImplementation("org.testcontainers:testcontainers:${rootProject.extra["testcontainersVersion"]}")
    testImplementation("org.testcontainers:postgresql:${rootProject.extra["testcontainersVersion"]}")
    testImplementation("org.testcontainers:junit-jupiter:${rootProject.extra["testcontainersVersion"]}")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:${property("springCloudVersion")}")
        mavenBom("com.google.cloud:spring-cloud-gcp-dependencies:5.8.0")
    }
}

tasks.bootJar {
    archiveBaseName.set("auth-service")
    archiveVersion.set("")
    archiveClassifier.set("")
}

tasks.jar {
    enabled = false
}
