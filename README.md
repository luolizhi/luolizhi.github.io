# back_up

## 新环境

在新的电脑上时，我们需要将项目先下载到本地，然后再进行hexo初始化。

```
git clone https://github.com/luolizhi/luolizhi.github.io.git --recursive
cd  luolizhi.github.io
npm install hexo
npm install hexo-cli -g
npm install
npm install hexo-deployer-git --save
```

之后开始写博客，写好部署好之后，别忘记 `git add .`,`git commit -m "update"`, `git push origin hexo` 推到 `hexo` 分支上去，然后使用 `hexo g -d` 部署上去。

`hexo` 常用的几个命令： 
```
$ hexo generate (hexo g) 生成静态文件，会在当前目录下生成一个新的叫做public的文件夹
$ hexo server (hexo s) 启动本地web服务，用于博客的预览
$ hexo deploy (hexo d) 部署播客到远端（比如github, heroku等平台）
$ hexo new "postName" #新建文章
$ hexo new page "pageName" #新建页面
```

常用简写

```
$ hexo n == hexo new
$ hexo g == hexo generate
$ hexo s == hexo server
$ hexo d == hexo deploy
```