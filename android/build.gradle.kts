allprojects {
    repositories {
        google()
        mavenCentral()
        maven { 
            url = uri("https://maven.google.com")
        }
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    project.evaluationDependsOn(":app")
}