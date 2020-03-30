# Supported tags and respective `Dockerfile` links
- [`7.3`, `latest`](https://github.com/Actency/docker-php-fpm/7.3/prod/Dockerfile)
- [`7.3-dev`](https://github.com/Actency/docker-php-fpm/7.3/dev/Dockerfile)

# How to use this image

### Create a `Dockerfile` in your PHP project

```dockerfile
FROM actency/docker-php-fpm:7.3
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
CMD [ "php", "./your-script.php" ]
```

Then, run the commands to build and run the Docker image:

```console
$ docker build -t my-php-app .
$ docker run -it --rm --name my-running-app my-php-app
```

### Run a single PHP script

For many simple, single file projects, you may find it inconvenient to write a complete `Dockerfile`. In such cases, you can run a PHP script by using the PHP Docker image directly:

```console
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp actency/docker-php-fpm:7.3 php your-script.php
```

## How to install more PHP extensions

Many extensions are already compiled into the image, so it's worth checking the output of `php -m` or `php -i` before going through the effort of compiling more.

We provide the helper scripts `docker-php-ext-configure`, `docker-php-ext-install`, and `docker-php-ext-enable` to more easily install PHP extensions.

### PHP Core Extensions

For example, if you want to have a PHP-FPM image with the `gd` extension, you can inherit the base image that you like, and write your own `Dockerfile` like this:

```dockerfile
FROM actency/docker-php-fpm:7.3
RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd
```

Remember, you must install dependencies for your extensions manually. If an extension needs custom `configure` arguments, you can use the `docker-php-ext-configure` script like this example. There is no need to run `docker-php-source` manually in this case, since that is handled by the `configure` and `install` scripts.

If you are having difficulty figuring out which Debian or Alpine packages need to be installed before `docker-php-ext-install`, then have a look at [the `install-php-extensions` project](https://github.com/mlocati/docker-php-extension-installer). This script builds upon the `docker-php-ext-*` scripts and simplifies the installation of PHP extensions by automatically adding and removing Debian (apt) and Alpine (apk) packages. For example, to install the GD extension you simply have to run `install-php-extensions gd`. This tool is contributed by community members and is not included in the images, please refer to their Git repository for installation, usage, and issues.

See also ["Dockerizing Compiled Software"](https://tianon.xyz/post/2017/12/26/dockerize-compiled-software.html) for a description of the technique Tianon uses for determining the necessary build-time dependencies for any bit of software (which applies directly to compiling PHP extensions).

### Default extensions

Some extensions are compiled by default. This depends on the PHP version you are using. Run `php -m` in the container to get a list for your specific version.

## Running as an arbitrary user

For running the Apache variants as an arbitrary user, there are several choices:

-	If your kernel [is version 4.11 or newer](https://github.com/moby/moby/issues/8460#issuecomment-312459310), you can add `--sysctl net.ipv4.ip_unprivileged_port_start=0` and then `--user` should work as it does for FPM.
-	If you adjust the Apache configuration to use an "unprivileged" port (greater than 1024 by default), then `--user` should work as it does for FPM regardless of kernel version.
-	Otherwise, setting `APACHE_RUN_USER` and/or `APACHE_RUN_GROUP` should have the desired effect (for example, `-e APACHE_RUN_USER=daemon` or `-e APACHE_RUN_USER=#1000` -- see [the Apache `User` directive documentation for details on the expected syntax](https://httpd.apache.org/docs/2.4/mod/mod_unixd.html#user)).

For running the FPM variants as an arbitrary user, the `--user` flag to `docker run` should be used (which can accept both a username/group in the container's `/etc/passwd` file like `--user daemon` or a specific UID/GID like `--user 1000:1000`).