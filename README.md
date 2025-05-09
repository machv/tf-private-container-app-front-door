# Container App demo via Front Door

Internal Container App Environment with App published externally via Front Door with Private Link connection

## Set Subscription ID via command-line
```
$SubscriptionId = az account show --query id -o tsv
$env:ARM_SUBSCRIPTION_ID = $SubscriptionId
terraform plan
```