# pycharm或者gogland配置读取kubernetes代码

1. 先下载kubernetes代码
2. 下载代码并解压出来并按照src\k8s.io\kubernetes新建目录，最后一级为下载的源码目录。
3. 接下来利用goland打开代码，到src一级。
4. 设置projectpath；添加下面三行
 C:\Users\lukey\Documents\code\go\k8s\src\k8s.io\kubernetes\vendor
 C:\Users\lukey\Documents\code\go\k8s\
 C:\Users\lukey\Documents\code\go\k8s\src\k8s.io\kubernetes\staging\src
5. 过一会，代码中的import就由红色变成绿色，就可以直接ctrl+点击到声明了。