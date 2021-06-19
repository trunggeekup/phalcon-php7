# phalcon-php7

#### build script
```
docker build -t registry-gitlab.geekup.io/prj_vision/phalcon-php7:2.0.1 .
```

- remove package: `python-software-properties`
    - software-properties-common sp already

- Install phalcon on lauchpad is outdate
    - using https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh    

- Update phalcon to 4.1.0
- 4.1.0 not auto convert UTF-8 -> need to handle manualy in src code