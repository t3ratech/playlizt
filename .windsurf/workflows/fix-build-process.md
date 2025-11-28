---
description: Fix Build Process
---

# Purpose

The purpose of this task is to fix the build process and unit tests from beginning to end. We must start with a clean slate, and end up with the system running end to end by using our build system. It is essential to understand the purpose of this task. The primary purpose of this task is to get the system up and running SPECIFICALLY with our playlizt-docker.sh script ONLY, and having ALL unit tests passing, and to build the system in a reliable, repeatable, predicatable way, therefore using commands outside of this script is absolutely failing the test, especially if the build succeeds with direct commands such as docker or docker compose. Once the build succeeds with external tasks, we have lost the ability to diagnose what the issue is and we have absolutely failed. Success is ONLY achieved by using our playlizt-docker.sh to build the system from beginning to end. NO OTHER SOLUTION IS ACCEPTABLE. ALL CODE CHANGES MUST HAPPEN IN THE IDE, ALL TERMINAL COMMANDS MUST HAPPEN IN THE IDE TERMINAL!

1. We must start by reading all rules to understand how to related to the system.
2. THIS IS VERY VERY IMPORTANT! You MUST then read and understand the system design: ARCHITECTURE.md before proceeding. EVERYTHING YOU DO MUST BE GUIDED BY THAT DOCUMENT!
3. We must also understand the build system, so read docker-composer.yml, .env and playlizt-docker.sh for understanding
4. We must start the build on a clean sheet, so we must use playlizt-docker.sh to destroy all module docker instances
5. The aim is not only to bring up the system (with all tests passing), but it is to bring up the system REALIABLY, PREDICTABLY, CONSISTENTLY every time using playlizt-docker.sh, and it means all steps must be validated very very in depth.

# Validation

We must bring up each module 1 by 1 very methodically. For each module, before we move to the next module we must validate the following:
1. We must validate that the commands we used to start the script were respected (if we used detatch, the system must start in detatched mode. If we specify 2 modules, ONLY those to modules must be started (unless we are in dependency resolution mode)
2. We must validate that the module is correctly logging by actually opening the logfile and seeing recent logs. The logs must be in the right timezone with the correct timestamp), and they must be in the right folder
3. We must validate that if we requested a rebuild, we must ensure that the jar file, or binary that is currently running in the dockerfile matches the timestamp and size of the recently built jar/binary and we must make sure the time is after our build command. We must also check running processes on the docker to ensure that this is newly compiled binary is actually the one referenced and currently running
4. We must validate our config files have been loaded correctly by checking the logs. If we are using both application.properties and application-dev.properties we must ensure both of them have been loaded by looking for a property that has been activated in each of them (eg. a DEBUG log or path).

# Fixing

1. DO NOT move onto the next module until the last module have been fully validated. We are not trying to bypass, or assist the script just to get the system working. We want the system to FAIL HARD when there is a problem, so that we can fix the problem, so that next time it will work REALIABLY, PREDICTABLY, CONSISTENTLY. STOP IMMEDIATELY AT THE FIRST ERROR and fix the problem so that next time it will work REALIABLY, PREDICTABLY, CONSISTENTLY, which might include fixing the build scripts, configs, code, etc. Do not circumvent an error which might happen again running a command directly on the docker image or the host machine. FIX THE ROOT CAUSE, ALWAYS!
2. DO NOT ever ever use default values as a fix, if there is a config missing, FAIL HARD so that we create the config, DO NOT bypass the error by using a failover
3. DO NOT ever hardcode values into code, or build scripts without consulting the user. All config values should be centralized so they can be documented and swapped out easily between environments. If this is complicated, ask the user, DO NOT make complicated changes without approval
4. All code changes must follow our architecture. Before you change any code, config or structure, make sure it is in line with the rest of the system, and our ARCHITECTURE.md, otherwise, ask the user first.
5. NEVER change the approach that is currently being used in the system without consulting the user

# Validating

1. When you make a change to the build process, start by destroying the existing docker image/logfile/jarfile and then rebuilding to see if you will now get past that issue REALIABLY, PREDICTABLY, CONSISTENTLY. We do not accept a solution that is not consistently reliable, it is considered failing.
2. Only work with 1 module at a time and validate everything before moving onto the next module (without touching the previous module if unneccesary)
3. Update the documentation if you see something that is inconsistent

# Verifying

1. You must run playlizt-api unit tests 1 class at a time starting with Authentication tests. Do not move on until all tests are passing. If an error occurs, understand what the correct solution is by reviewing the ARCHITECTURE.md and checking the existing patterns in other modules, then fix the error. If the function or class is not implemented, then implement it end to end, carefully and completely using the ARCHITECTURE.md. Once 1 class is working, move on to the next class and repeat the process until unit test classes are passing completely. YOU MAY NOT COMMENT OUT CODE OR TESTS to get them to pass. You must fix the issue or implement the solution.
2. Once you are done with playlizt-api, run the UI tests in the same manor as the API tests, 1 by 1, making sure they are green before moving on, and fixing or implementing the required stuff based on ARCHITECTURE.md and other modules.

The task is complete when you can run playlizt-docker.sh --rebuild-all and the whole system builds, and ALL unit tests and AND playright tests pass end to end, then you can validate that everything mentioned above is working correctly without any intervention.