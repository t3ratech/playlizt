plugins {
    java
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

extra["springCloudVersion"] = rootProject.extra["springCloudVersion"]

dependencies {
    // Spring Cloud Gateway
    implementation("org.springframework.cloud:spring-cloud-starter-gateway")
    
    // Spring Cloud
    implementation("org.springframework.cloud:spring-cloud-starter-netflix-eureka-client")
    
    // Actuator
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    
    // Annotation processor
    annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")
    
    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:${property("springCloudVersion")}")
    }
}

tasks.bootJar {
    archiveBaseName.set("api-gateway")
    archiveVersion.set("")
    archiveClassifier.set("")
}

tasks.jar {
    enabled = false
}
