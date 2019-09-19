#install roles
sfdx force:source:deploy --sourcepath ./force-app/main/default/roles --json --loglevel fatal && \
#install workflows
sfdx force:source:deploy --sourcepath ./force-app/main/default/workflows --json --loglevel fatal && \
#install approval process
sfdx force:source:deploy --sourcepath ./force-app/main/default/approvalProcesses --json --loglevel fatal #&& \

#additionaly install profiles
#sfdx force:source:deploy --sourcepath ./force-app/main/default/profiles --json --loglevel fatal && \