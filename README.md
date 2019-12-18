# active-directory-b2c-dotnetcore-webapp
clone of https://github.com/Azure-Samples/active-directory-b2c-dotnetcore-webapp

## Why did I clone it?
Because I've made local changes that I want to both save and share. Also, because when you work with B2C Custom Policies you need a WebApp to test them with.

## What are the changes?
- appsettinbgs.json can hold multiple configurations and you just change the value of AzureAdB2C-Config to point to which config you want to work with
- More B2C Policy options, like ability to test Sign-up and Sign-in separatly, Change password and Forgot Password separatly.
- Change on index page so that it shows relevant info and links about B2C 
- Drop down menu with options after you have signed in
- Ability to handle "invite by email" scenario where the WebApp handles calls like /Session/Signup?email=donald.duck@disney.com and pass that value to the B2C policy (SessionController.cs + OpenIdConnectOptionsSetup.cs)
- Handeling of AADB2C90118 in Forgot Password scenarios so that a separate B2C policy can be invoked

## How To Run This Sample?
Check instructions here https://github.com/Azure-Samples/active-directory-b2c-dotnetcore-webapp/blob/master/README.md

## Versions used
I built this code with Visual Studio 2019 and dotnet core 2.2 
