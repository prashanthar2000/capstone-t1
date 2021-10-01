CLUSTER_NAME=capstone-t1
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
CIDR_BLOCK=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[].CidrBlock" --output text)

MOUNT_TARGET_GROUP_NAME="eks-efs-group"
MOUNT_TARGET_GROUP_DESC="NFS access to EFS from EKS worker nodes"
MOUNT_TARGET_GROUP_ID=$(aws ec2 create-security-group --group-name $MOUNT_TARGET_GROUP_NAME --description "$MOUNT_TARGET_GROUP_DESC" --vpc-id $VPC_ID | jq --raw-output '.GroupId')
aws ec2 authorize-security-group-ingress --group-id $MOUNT_TARGET_GROUP_ID --protocol tcp --port 2049 --cidr $CIDR_BLOCK

FILE_SYSTEM_ID=$(aws efs create-file-system | jq --raw-output '.FileSystemId')

#wait till the filesystem is available ( gussing it would take 5 mins cant say anything for sure)
echo " wait again if it is still in creating state.. proceede if it is available"
sleep 5m
# aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID  | jq --raw-ouput '.FileSystems[].LifeCycleState' # should be equal to available
aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID 

sleep 45

TAG1=tag:alpha.eksctl.io/cluster-name
TAG2=tag:kubernetes.io/role/elb
subnets=($(aws ec2 describe-subnets --filters "Name=$TAG1,Values=$CLUSTER_NAME" "Name=$TAG2,Values=1" | jq --raw-output '.Subnets[].SubnetId'))
for subnet in ${subnets[@]}
do
    echo "creating mount target in " $subnet
    aws efs create-mount-target --file-system-id $FILE_SYSTEM_ID --subnet-id $subnet --security-groups $MOUNT_TARGET_GROUP_ID
done


echo "wait till it is available"
sleep 5m 
aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.MountTargets[].LifeCycleState'

sleep 45 


kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.0"
kubectl get pods -n kube-system

wget https://eksworkshop.com/beginner/190_efs/efs.files/efs-pvc.yaml
sed -i "s/EFS_VOLUME_ID/$FILE_SYSTEM_ID/g" efs-pvc.yaml
kubectl apply -f efs-pvc.yaml

kubectl get pvc -n storage
kubectl get pv
