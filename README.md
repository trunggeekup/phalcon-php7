# phalcon-php7

#### build script
```
docker build --platform linux/amd64 \
    -t registry-gitlab.geekup.io/prj_vision/phalcon-php7:2.0.2 \
    -t trungjs/phalcon-php7:latest \
    -t trungjs/phalcon-php7:2.0.2 .
```

#### push image to docker hub
```
docker push -a registry-gitlab.geekup.io/prj_vision/phalcon-php7
docker push -a trungjs/phalcon-php7
```

- remove package: `python-software-properties`
    - software-properties-common sp already

- Install phalcon on lauchpad is outdate
    - using https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh    

- Update phalcon to 4.1.0
- 4.1.0 not auto convert UTF-8 -> need to handle manualy in src code