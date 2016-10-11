---
layout: post
title:  "Angular 2 build with maven"
date:   2016-10-9 14:30:39 +0600
categories:
tags: Angular2 Npm Maven Build
---

A few weeks ago Google published Angular 2.0 final release. I've already tried it and I like it. However, if you 
face with some problem, it probably will be difficult to find solution in the internet. Angular2 has been strongly changed 
since rc1 was published. That's why there are a lot of outdated information. I think we must fix this problem and 
publish a lot of articles and posts about angular2. My contribution is article about building the application with 
angular2 client. 

 
### Build requirements

I used to have following features in client build system:

* Dependency management
* Build for development with debugging and proxy
* Build for production (compressed)
* Check style
* Unit tests
* E2E tests

### Possible implementations

Angular2 tutorial recommends us to use npm as a dependency manager. As I know, Bower is officially not supported,
but there are some ways to use it. In short, now the package manager is npm without alternatives.

Firstly I tried to use gulp to write build script. I've almost done it, but the system was too complicated. 
For example, I remember that using bower with custom gulp build script I had to write simple string 
'bower install smth --save' to add a
dependency. I couldn't achieve the same usability for my custom gulp system due the fact that I'm responsible not only 
for adding it, but also for compiling typescript to javascript.

Then I found [Angular-CLI][angularCli]{:target="_blank"} project. It has all features I want. It also gives an 
interface for easy creating angular2 applications. For example, this command generates ready component even 
with unit test.
 
 {% highlight bash %}
 ng g component my-new-component
 {% endhighlight %}
 
 However, to add a dependency I have to write it in two places: package.json and angular-cli.json file. 
 I don't like it, anyway it is standard and a newer won't have problems with it.
 
 Angular-CLI is also google's project. I expect it will be supported and it will have a huge community. So you won't 
  stay with a problem alone. My choice is definitely angular-cli.

### Integration with maven

I have a multi-module maven application. It has a few server modules and one client module. So, the structure is like 
this:

 {% highlight bash %}
 app
    app-client
        dist 
        src
        proxy-config.json (will be added)
        ...
        pom.xml
    app-webapp
        pom.xml
    ...
    pom.xml
    
 {% endhighlight %}
 
 I skipped some files and modules that are not mentioned in this article. The client application has been
 created with angular-cli (using ng new). Starting from this state step by step I'll show my build system.

#### Add proxy 

I used to launch the server at port 8080, but client serves at 4200 port. So I need to proxy some requests 
from 4200 to
8080 port. To do it with angular-cli just add proxy config file (proxy-config.json) in client's root.

  {% highlight json %}
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false
  }
}
   {% endhighlight %}
   
To enable proxy just add option --proxy-config proxy-config.json to serve command.
   
#### Npm scripts
   
   I'm going to use frontend-maven plugin. It downloads node and npm and performs
 necessary commands. The following modification of scripts part of package.json allows 
 to run all necessary angular-cli commands with npm.

  {% highlight json %}
 "scripts": {
     "start": "ng serve --proxy-config proxy-config.json",
     "build": "ng build --dev",
     "prod" : "ng build --prod",
     "lint": "tslint \"src/**/*.ts\"",
     "test": "ng test",
     "pree2e": "webdriver-manager update",
     "e2e": "protractor"
   },
   {% endhighlight %}
   
   For example, now I need run simple 'npm run-script start' for serving the client with proxy.
   
 
#### Run npm tasks from maven
 
 Here is my client's pom.xml. It has two plugins. First one cleans dist directory where production client build 
 is situated. The second one launches two npm scripts: npm install and npm run-script prod. 
  It is very important don't forget --prod option in package.json, without it a result build will be not optimized.
   If you want, you can add more npm scripts with test or check style. 
 
 {% highlight xml %}
 <build>
     <plugins>
 
       <plugin>
         <artifactId>maven-clean-plugin</artifactId>
         <version>2.5</version>
         <configuration>
           <filesets>
             <fileset>
               <directory>dist</directory>
               <includes>
                 <include>*</include>
               </includes>
             </fileset>
           </filesets>
         </configuration>
       </plugin>
 
       <plugin>
         <groupId>com.github.eirslett</groupId>
         <artifactId>frontend-maven-plugin</artifactId>
         <version>${frontend-maven-plugin.version}</version>
         <executions>
           <execution>
             <id>install node and npm</id>
             <goals>
               <goal>install-node-and-npm</goal>
             </goals>
             <configuration>
               <nodeVersion>${node.version}</nodeVersion>
               <npmVersion>${npm.version}</npmVersion>
             </configuration>
           </execution>
 
           <execution>
             <id>npm install</id>
             <goals>
               <goal>npm</goal>
             </goals>
             <configuration>
               <arguments>install</arguments>
             </configuration>
           </execution>
 
           <execution>
             <id>prod</id>
             <goals>
               <goal>npm</goal>
             </goals>
             <configuration>
               <arguments>run-script prod</arguments>
             </configuration>
             <phase>generate-resources</phase>
           </execution>
         </executions>
       </plugin>
     </plugins>
   </build>
    {% endhighlight %}

#### Add optimized production build to war

I use maven-war-plugin to put client to war. It just copies a directory. Here is my pom.xml from app-webapp module. 
I made this module depending on app-client, to provide that dist directory will be already created when 
maven-war plugin starts working. 
 {% highlight xml %}
<dependencies>
                <dependency>
                    <groupId>groupId</groupId>
                    <artifactId>app-client</artifactId>
                    <version>1.0-SNAPSHOT</version>
                </dependency>
            </dependencies>
            <build>
                <plugins>
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-war-plugin</artifactId>
                        <version>2.6</version>
                        <configuration>
                            <webResources>
                                <resource>
                                    <!-- this is relative to the pom.xml directory -->
                                    <directory>../app-client/dist/</directory>
                                </resource>
                            </webResources>
                        </configuration>
                    </plugin>
                </plugins>
            </build>
 {% endhighlight %}

That's it. Now mvn clean package command builds either server and client sides and packs it into war. 

[angularCli]: https://github.com/angular/angular-cli