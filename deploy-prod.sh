#!/bin/bash

# Update AWS EKS user config
aws eks update-kubeconfig --region ap-northeast-2 --name $AWS_EKS_CLUSTER_NAME

# Deploy kubernetes deployment resource
if ! kubectl get deployment config-deployment &> /dev/null; then
  echo "Create new kubernetes deployment resources..."
  kubectl create -f ./deployment-prod.yml
else
  echo "Apply new docker image "
  kubectl set image deployments/config-deployment config-service=$ECR_REGISTRY/$AWS_ECR_REPOSITORY:$IMAGE_TAG --record
fi

# Check if deployment deploy is successful
if ! kubectl get deployment config-deployment &> /dev/null; then
  echo "Failed to create new kubernetes deployment resources"
else
  echo "Success to create new kubernetes deployment resources"

  # Check if the rollback was successful
  if ! kubectl rollout status deployment/config-deployment --watch=false | grep -q "successfully rolled out"; then
    echo "Rolling update has failed. Initiating rollback..."

    kubectl rollout undo deployment/config-deployment
    kubectl rollout status deployment/config-deployment --watch=true

    # Check one more time if the rollback was successful
    if kubectl rollout status deployment/config-deployment --watch=false | grep -q "successfully rolled out"; then
      echo "Rollback was successful."
    else
      echo "Rollback failed. Manual intervention required."
    fi
  else
    echo "Rolling update was successful. No rollback needed."

    # Deploy kubernetes service resource
    if ! kubectl get service config-service &> /dev/null; then
      echo "Create new kubernetes service resources..."
      kubectl create -f ./service-prod.yml
    else
      echo "Apply existing kubernetes service resources..."
      kubectl apply -f ./service-prod.yml
    fi

    # Check if service deploy is successful
    if ! kubectl get service config-service &> /dev/null; then
      echo "Failed to create new kubernetes service resources"
    else
      echo "Success to create new kubernetes service resources"
    fi
  fi
fi


