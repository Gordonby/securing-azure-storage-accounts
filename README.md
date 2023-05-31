# securing-azure-storage-accounts

Storage use case, receiving incremental files into a storage account that are invaluable.
Data protection is paramount, secondary consideration is cost as the growth of the storage account is 10Tb/day.

## Protecting files from being overwritten/deletion

### Immutable Storage Policy

There are two methods of implementing immutable storage;

1. Time Based - When the interval is known
2. Legal hold - When the interval is unknown

## Protecting files from deletion

### Soft delete

When an immutable storage policy is in place, it should not be possible to delete files in containers that have the policy applied. For containers in the storage account that do not have an immutable storage policy, Soft Delete is the next level of protection. Is also serves as a "safety net" in the event of Storage Policies being removed and files subsequently being deleted. 

#### Cost

Soft-deleted data is billed at the same rate as active data.

#### Alerting

In the event data is deleted, we can capture this event.

1. Notification
2. Automatic undelete

## Protecting a storage account

### Delete locks

Delete locks are a simple way to prevent Storage Accounts from being inadvertantly deleted. Delete locks are commonly used to protect production services from erroneous deployment actions. They are however very quick to remove by a user with the right RBAC permissions.

### Deny Role Assignment

Deny assignments prevent users from performing specific Azure resource actions even if another role assignment grants them access. This means we can create a Deny Role Assignment to prevent users from performing operations like `Storage Account delete` and `Lock removal` at specific scopes.

Deny Role Assignments are part of Azure Blueprints; https://learn.microsoft.com/en-us/azure/governance/blueprints/concepts/resource-locking
They can be applied at the Management Group level, which also affords additional protection from users who's permissions are scoped at the Subscription level from performing malicious actions.

## Azure Policy

Azure Policies are leveraged for the control plane deployment operations. They can be used to ensure the configurations identified above are mandatory through Append and Deny assignments.

### Soft delete policy definition

A policy to ensure a Soft Delete period of 365 days.

```json
{}
```

### Immutable policy definition

A policy to ensure a Legal Hold Immutable Storage Policy is applied to all Containers.

```json
{}
```

## Remaining Risks

After implementing the protections above, the data in your storage accounts will be well protected.

Risks 

- Users can exclude resources from Azure Policy Assignments
- Users with standing access at the Management Group level can remove deny assignments.

Ways to mititage

- Leverage PIM 
- Notifications
