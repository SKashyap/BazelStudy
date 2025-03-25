# Packaging options for common libraries

At Figure, we are deploying N applications using TensorFlow and other shared libraries in common. We are exploring three packaging options, 
(1) a Debian package for each application and each shared library 
(2) a single docker image containing all the applications and the shared libraries 
(3) or a docker image for each application containing the shared libraries used by the application.


## What would be your process to select the right solution?

I would ideally ask these questions first:
- What is the deployment architecture of these N applications. Target deployment platform matters to our decision. 
- How each of the N applications consumes the shared library in question.
- Do we have a set of libraries identified as a "Shared kernel" for all applications developed in this organization?
- Understand the dependency between the N applications and the shared kernel.
- Do all libraries within this "Shared kernel" have a similar frequency of updates? We typically don't want to group a frequently changing library with a rare one and call it a shared kernel.
- what is the size of this kernel? how many shared libraries are present?


## What are the pros/cons of each approach?

#### A Debian package/RPM for each application and each shared library:
- Con: Installation logic becomes complex. Each Application RPM must list its dependent RPMs. Their installation needs to be ordered by the installer.
- Pro: Works well when we require a tight integration with the host system on which these packages are installed. Ie, we have the host platform under our control. Example: VSphere Control Plane is a single large Hat Linux VM that runs N services or applications. Each service has its own package (rpm) and a common set of shared libs are installed as different rpms. Example: Boost libraries. Whereas, other libs whose usage may not be unified are packaged along with the application rpm and installed within it's directories. 
- Pro: Partial upgrade possible for clients. When a shared lib has a minor upgrade, we don't need to rebuild all application binaries as long as there is ABI compatibility. Example: security patch on a third party lib. 
- Such a distribution architecture only works for dynamic linking and allows code reuse by N applications.
- Pro: Management of library versions may be simpler with a Jenkins pipeline build each shared lib at a pinned version and spitting out a debian package.
- Con: Application deployment does not come out of the box like in case of docker. 
- Con: Not a very suitable way to deploy applications to the cloud.
- Pro: RPMs can be used to build layers in our application-specific docker image. So, we can cater to teams needing container images as well as packages at the same time. 
  

#### A single docker image containing all the applications and the shared libraries: 
Con: Not at all a practical distribution for separate applications. 
Con: The smallest change of a single lib invalidates all deployed instances of all applications. The touch surface gets amplified over N applications. Rebuild every app when a new library version is introduced.
Con: docker size will become huge
Con: Makes way for a lot of coupling between N applications.
Pro: The version is easy since the docker generates a new hash for each change. 
Con: SCA(software component analysis) and security become tedious with multiple dependencies.

#### A docker image for each application containing the shared libraries used by the application: 
- Pro : Most suitable to the modern microservice architectures and simplifies deployment of each application. 
- Pro: isolation between the N applications. If components A and B both depend on shared library X, and X has a “minor” version bump that A needs but it happens to break B, you’re not in shared-library trouble, because the two components have their own copies of the library stack.
- Pro: De-couples lifecycle management(upgrade etc) of the N applications.
- Pro: Allows different versions of shared-lib association for each application.
- Pro: A common kernel of shared-libs can be used to build a base image which all N applications can derive from.
- Pro : rebuild-redeploy-test only those apps that need Lib A when a new library version of A is introduced.
   
## Should we use static or dynamic libraries?

