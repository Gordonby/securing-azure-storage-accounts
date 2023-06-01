# Securing Azure Storage Accounts

This repo delves into the various protections that are available in Azure for protecting business critical data.

The scenario is scoped to Azure Blob data in Azure Storage Accounts, Backup is out of scope.

This repository includes Infrastructure as Code assets in addition to describing the concepts, and showing the imposed controls.

## Durability

[Zone redundant](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy#zone-redundant-storage) storage offers the highest storage SLA and spreads 3 copies of your data over 3 availability zones. [Locally redundant](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy#locally-redundant-storage) on the other hand keeps 3 copies of your data in the same data center.

[Geo-zone redundant](https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy#geo-zone-redundant-storage) replicates to a secondary region to mitigate primary region data-loss scenarios.

> GZRS should be used for providing maximum durability for business critical data

### Cost

This pricing illustration is for capacity only, based on 1TB block blob storage in UK South. Pricing correct as of 31st May 2023, averaged monthly cost.

Redundancy | Access Tier | Cost 
---------- | ----------- | ----
LRS | Hot | £15.60
ZRS | Hot | £19.71
GRS | Hot | £31.21
GZRS | Hot | £35.48

## Protecting blobs from being overwritten/deletion

### Immutable Storage Policy

There are two methods of [implementing immutable (WORM) storage](https://learn.microsoft.com/azure/storage/blobs/immutable-storage-overview);

1. Time Based - When the interval is known
2. Legal hold - When the interval is unknown

Legal holds can be applied and removed at any time by users with sufficient access. Time based policies are much more rigorous in that once placed in the locked state all data is protected until the retention time period has passed. After the retention period has passed the data can then be deleted.

> When you create a time based immutable storage lock it is created in the unlocked state. You must explicitly put the policy in the locked state.

#### Effect of an immutable storage policy - unlocked state

Attempted Operation | Result | Message
------------------- | ------ | -------
Overwrite | ![overwrite error](assets/immutable-worm.png) | This operation is not permitted as the blob is immutable due to a policy
Delete | ![delete error](assets/immutable-worm-delete.png) | Failed to delete 1 out of 1 blobs. This operation is not permitted as the blob is immutable due to a policy. Policies are applied at the Storage Container level.

#### Effect of an immutable storage policy - locked state

Whilst the policy exists, and is enforced in the unlocked state, moving to the locked state provides absolute protection.

![locked state confirmation](assets/locking-policy.png)

> During testing of time based immutable policies, use a low number of days for the retention period. Deleting a locked immutability policy is not allowed, the only way is to delete the container is to wait until the retention period expires and them deleting all expired blobs inside the policy locked container. 


## Protecting blobs from deletion

### Soft delete

When an immutable storage policy is in place, it should not be possible to delete files in containers that have the policy applied. For containers in the storage account that do not have an immutable storage policy, Soft Delete is the next level of protection. Is also serves as a "safety net" in the unlikely event of Storage Policies being removed and blobs subsequently being deleted. 

#### Cost

Soft-deleted data is billed at the same rate as active data.

## Protecting a storage account

### Delete locks

Delete locks are a simple way to prevent Storage Accounts from being inadvertently deleted. Delete locks are commonly used to protect production services from erroneous deployment actions. They are however very quick to remove by a user with the right RBAC permissions.

### Deny Role Assignments

Deny assignments prevent users from performing specific Azure resource actions even if another role assignment grants them access. This means we can create a Deny Role Assignment to prevent users from performing operations like `Storage Account delete` and `Lock removal` at specific scopes.

Deny Role Assignments are part of Azure Blueprints; https://learn.microsoft.com/en-us/azure/governance/blueprints/concepts/resource-locking
They can be applied at the Management Group level, which also affords additional protection from users who's permissions are scoped at the Subscription level from performing malicious actions.

## Azure Policy

Azure Policies are leveraged for the control plane deployment operations. They can be used to ensure the configurations identified above are mandatory through Append and Deny assignments.

Policies can be assigned at the Resource Group, Subscription or Management Group scope. Assigning a policy at a higher scope prevents users that only have permissions at lower scopes from making exemptions/changes to the assignment.

A list of community/microsoft Azure Policy definitions can be seen on [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer_all.html#%7B%22col_7%22%3A%7B%22flt%22%3A%22deleteRetentionPolicy%22%7D%7D)

## Summary

Time based, locked immutable policies provide the ultimate level of protection for your data, but create an rigid configuration that needs to be right for the data and your business so should be adopted carefully.

The bicep file [storage.bicep](storage.bicep) shows how to create a Storage Account with several of the configurations discussed.

[azPolicy-softdelete.bicep](azPolicy-softdelete.bicep) creates a Subscription Scoped Azure Policy to address the Soft Delete configuration with `deny` and `modify` policy effects.

### Remaining Risks

Depending on the controls selected, malicious users could obtain high level access can systematically remove the controls before deleting a storage account.
- With the right permissions, users can exclude resources from Azure Policy Assignments
- Users with standing access at the Management Group level can remove deny assignments.

Ways to mitigate;

- Remove standing access to production environments and leverage [Privileged Identity Management (PIM)](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-configure) for RBAC role elevation.
- [Resource Guard](https://learn.microsoft.com/azure/backup/multi-user-authorization?pivots=vaults-recovery-services-vault&tabs=azure-portal) (PIM feature) in Azure Backup
- Notifications on Azure events such as blob/container delete

### Notifying on blob delete

An event grid subscription can be created to take remediation or notification actions.

![blob delete event](assets/eventgrid.png)

