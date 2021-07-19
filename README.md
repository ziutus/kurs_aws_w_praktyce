# kurs_aws_w_praktyce

Materiały i rozwiązania ćwiczeń z kursu ["AWS w praktyce – pierwszy projekt w chmurze"](https://szkolachmury.pl/oferta/aws-w-praktyce-pierwszy-projekt-w-chmurze/) prowadzonym przez [Karolinę Boboli](https://www.linkedin.com/in/karolinaboboli) z [Szkola Chmury](https://szkolachmury.pl).

 aws cloudformation list-stacks --query "StackSummaries[].StackName | sort(@)"

 aws cloudformation list-stacks --query "StackSummaries[].[StackName,StackId,StackStatus]"

 not working!:
 aws cloudformation list-stacks --query 'StackSummaries[].[StackId,StackName,StackStatus][?"StackStatus"!="DELETE_COMPLETE"]'

 working:
 aws cloudformation list-stacks --query 'StackSummaries[].[StackId,StackName,StackStatus][?"StackStatus"=="DELETE_COMPLETE"]'

 aws cloudformation list-stacks --query 'StackSummaries[].[StackId,StackName,StackStatus][?"StackStatus"=="DELETE_COMPLETE"] | [0]'

 aws cloudformation list-stacks --query 'StackSummaries[0:4].{"ID":StackId,"Name":StackName,"Status":StackStatus}'
