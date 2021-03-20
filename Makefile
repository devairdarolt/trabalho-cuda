all:
	scp +cudasort/* alu2020s2@ens3:~/trabalho-cuda/+cudasort/

push: 
	git add *
	git commit -m "New Commit"
	git push
	
