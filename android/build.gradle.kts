allprojects {
    repositories {
        google()
        mavenCentral()
        maven { 
            url = uri("https://maven.google.com")
        }
    }
}

rootProject.layout.buildDirectory.set(rootProject.file("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.file("../build/${project.name}"))
}

subprojects {
    project.evaluationDependsOn(":app")
}