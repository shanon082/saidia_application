###### saidia_app

A new Flutter project.

## Getting Started





## convert to apk
- Download commandlinetools for windows or linux.

- Extract them to the C:\Android\Sdk\latest and add the to the environment variables.
Check by using 
# flutter doctor -v
# sdkmanager --version  
# sdkmanager --list
# sdkmanager "platform-tools"

- Download Java sdk and add it to the environment variables
verify by 
# java -version

- converting to apk "& "C:\Program Files\Java\jdk-25.0.2\bin\keytool.exe" -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload" 
then follow steps

# flutter build apk --release --split-per-abi




