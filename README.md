# back_up

## 新环境

在新的电脑上时，我们需要将项目先下载到本地，然后再进行hexo初始化。

```
git clone https://github.com/luolizhi/luolizhi.github.io.git
cd  luolizhi.github.io
npm install hexo
npm install
npm install hexo-deployer-git --save
```

之后开始写博客，写好部署好之后，别忘记 `git add .`,`git commit -m "update"`, `git push origin hexo` 推到 `hexo` 分支上去，然后使用 `hexo g -d` 部署上去。