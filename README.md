# bamboohr-dates-motd

It is a script to show [https://www.bamboohr.com/] information as compact form to use like linux [motd] files

It outputs like
```sh
vlad@dnipro:~/src/k116/bamboohr-dates-motd$ ruby ./bamboohr.rb
PV_10;-15;Petr Ivanoff;-2 20180909 20180922
PV_10;-14;Ivan Petroff;-2 20180910 20180922
OOO_2;4;Artem Anikeev;8 20180928 20181002
```
PV means Paid Vacation
OOO - work Outside of Office
Duration and how many days left to start, finish event also displayed

You should to set environment variable like
```sh
export ICAL_FEEDS="HappyBirday:https://link_to_your_ical_data;Anniversary:http://appropriative.link"
# the # sign is delimiter for ical feeds
```


[https://www.bamboohr.com/]: <https://github.com/markdown-it/markdown-it>
[motd]: <https://wiki.debian.org/motd>

