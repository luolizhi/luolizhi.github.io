hexo generate
cp -R public/* .deploy/luolizhi
cd .deploy/luolizhi
git add .
git commit -m update
git push origin master