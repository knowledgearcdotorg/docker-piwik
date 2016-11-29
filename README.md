# KnowledgeArc.org Piwik Docker Image
KnowledgeArc provides an open source Docker image of the Piwik open source analytics platform on Ubuntu.

The image uses PHP FastCGI Process Manager (php-fpm) to process Piwik's PHP and is designed to run with the Knowledgearcdotorg/Apache2 Docker container as the front-facing web server (this setup is covered in this README).

The Piwik Docker image includes the Maxmind GeoIPCity Lite database which is freely available from the Maxmind web site.

The Piwik web application is not pre-installed; you will need to launch the Piwik web installer to complete the setup.

## Getting Started

To launch a Piwik container, run:

```
sudo docker run --name=container-name knowledgearcdotorg/piwik
```

where --name=container-name is a user-friendly reference to the docker container.

For example, to launch a container with the name "piwik" run:

```
docker run --name=piwik knowledgearcdotorg/piwik
```

To run the container in detached mode, add the -d option:

```
docker run -d --name=piwik knowledgearcdotorg/piwik
```

You can check the status of the newly created container by running:

```
docker logs piwik
```

## Adding a Database

Piwik relies on MySQL for its storage requirements but in keeping with Docker's single process philosophy, there is no MySQL server bundled with the Piwik image. Instead, it is recommended you run a separate MySQL container using the <a href="https://github.com/knowledgearcdotorg/docker-mysql" target="_blank">knowledgearcdotorg/mysql</a> image for the Piwik database. This README does not cover the deployment of a MySQL database; instead, check out https://github.com/knowledgearcdotorg/docker-mysql/blob/master/README.md.

Once you have your MySQL container running, you will need to create a database for Piwik. It is also highly recommended you create a new user who only has access to the Piwik database. You can do this by running MySQL commands via Docker's exec command. You will need the MySQL container's root password to complete the following steps:

```
docker exec mysql mysql -u root --password=myrootpassword -e "CREATE DATABASE piwik CHARACTER SET utf8;"
docker exec mysql mysql -u root --password=myrootpassword -e "GRANT ALL PRIVILEGES ON piwik.* TO piwik@piwik IDENTIFIED BY 'piwikpassword';"
docker exec mysql mysql -u root --password=myrootpassword -e "FLUSH PRIVILEGES;"
```

## Serving it via the Web

PHP FPM is a PHP processor it is not a full-blown web server. Instead, you will want to proxy requests for PHP through a web server such as Apache HTTPD. For ease of setup, there is a knowledgearcdotorg/apache2 image available and it is recommended you use this as your front-end web server.

Because PHP FPM only handles PHP, and because Piwik does not separate PHP files from other, static assets (Javascript, CSS, images, etc), you will need to ensure the Piwik file system is available to both the Piwik and Apache2 containers. This is easily achieved using a Docker volume.

Start by launching a new volume:

```
docker volume create --name=www-data
```

Next, run a Piwik container, using the new volume as your file store:

```
 docker run -v www-data:/var/www/ --name piwik knowledgearcdotorg/piwik
```

Apache2 should now be run, and will reference the same volume:

```
 docker run -v www-data:/var/www/ -p 80:80 --name apache2 knowledgearcdotorg/apache2
```

You will now need to add an VirtualHost definition to Apache2 and enable it. The VirtualHost definition for Piwik is available from https://raw.githubusercontent.com/knowledgearcdotorg/docker-piwik/master/etc/apache2/sites-available/piwik.conf:

```
sed -i -e 's/{domain}/piwik.domain.tld/g' -e 's/{container}/piwik/g' piwik.conf
docker cp piwik.conf apache2:/etc/apache2/sites-available/
docker exec apache2 a2ensite piwik
```

Note the two placeholders; {domain} and {container}. You will need to use sed to substitute these placeholders with the actual domain and container name.

Finally, restart the Apache2 Docker container to load the new changes:

```
docker restart apache2
```

## Running the Piwik Installer

The Apache2 container should now be serving the Piwik web installer. Use the credentials you created for MySQL when setting up the database connection (host will be the name of your MySQL container) and complete the setup wizard.

Your new Piwik analytics platform should now be running.