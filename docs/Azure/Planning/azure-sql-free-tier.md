# Azure SQL Database Free Tier

**Last Updated:** January 13, 2026  
**Cost Level:** Free (with limits)  
**Service Tier:** General Purpose Serverless

## Overview

Azure SQL Database offers a completely free tier with generous limits perfect for POC applications. Each Azure subscription can have up to **10 free databases** that include compute, storage, and backup at no cost for the lifetime of the subscription.

## Key Features

- **100,000 vCore seconds/month** of serverless compute per database
- **32 GB data storage** per database
- **32 GB backup storage** per database
- **Up to 10 databases per subscription**
- **Auto-pause capability** when limits are reached
- **7-day point-in-time restore**
- **Free for the lifetime of your subscription**

### Compute Translation
100,000 vCore seconds/month approximately equals:
- ~27.7 hours of continuous 1-vCore activity
- Perfect for POCs with intermittent usage patterns

## Cost Analysis

### Free Tier (Within Limits)
| Resource | Monthly Limit | Cost |
|----------|---------------|------|
| Compute | 100,000 vCore seconds | **$0.00** |
| Storage | 32 GB | **$0.00** |
| Backup Storage | 32 GB | **$0.00** |

### If Exceeds Free Limits
| Scenario | Estimated Monthly Cost |
|----------|----------------------|
| Minimal overage (auto-pause disabled) | ~$4.78 |
| Light continuous usage | ~$5-15 |
| Moderate usage | ~$15-30 |

**Serverless Compute Rate:** ~$0.000105 per vCore per second

### Multi-Database Cost Example
**5 POC Applications** (each with own database):
- **Total storage capacity:** 160 GB (32 GB × 5)
- **Total monthly compute:** 500,000 vCore seconds
- **Estimated cost:** **$0.00** if apps stay within individual limits

## Shared Resource Group Architecture

### Recommended Setup
1. **One logical SQL server** in shared resource group
2. **Multiple free databases** on that server (up to 10)
3. **Shared firewall and authentication** configuration
4. **Isolated data** - each app has its own database

### Benefits
- ✅ Centralized management
- ✅ Shared security configuration
- ✅ Each database gets full 100K vCore seconds allowance
- ✅ Simplified connection string management
- ✅ Common backup and maintenance policies

### Architecture Diagram
```
Resource Group: rg-shared-poc
└── Logical SQL Server: sql-poc-shared
    ├── Database: db-aspire-app (32 GB, 100K vCore-sec/mo)
    ├── Database: db-polymarket-clone (32 GB, 100K vCore-sec/mo)
    ├── Database: db-spa-backend (32 GB, 100K vCore-sec/mo)
    ├── Database: db-worker-state (32 GB, 100K vCore-sec/mo)
    └── Database: db-mcp-storage (32 GB, 100K vCore-sec/mo)
```

## Limitations

### Technical Constraints
- **Max 4 vCores** per database when auto-pause enabled
- **7-day PITR** (point-in-time restore) vs 35 days for paid
- **Locally redundant storage only** (no geo-redundancy)
- **Cannot use elastic pools** with free databases
- **Cannot use failover groups**
- **No long-term backup retention**
- **No Elastic Jobs or DNS Alias support**

### Regional Constraints
- **All free databases in a subscription must be in the same region**
- Region is locked after first free database creation
- Choose your region carefully!

### Behavior Options

#### 1. Auto-Pause (Recommended for POCs)
```
When limits reached: Database pauses automatically
Resumes: Beginning of next calendar month
Cost when paused: $0.00
Best for: POCs with acceptable downtime at month-end
```

#### 2. Continue with Charges
```
When limits reached: Database continues running
Billing: Standard serverless rates apply
Cost: ~$4.78-15/month depending on usage
Best for: POCs requiring 100% uptime
Note: Cannot revert to auto-pause once enabled
```

## Implementation Steps

### 1. Create Logical SQL Server
```bash
# Azure CLI
az sql server create \
  --name sql-poc-shared \
  --resource-group rg-shared-poc \
  --location eastus \
  --admin-user sqladmin \
  --admin-password <strong-password>
```

### 2. Configure Firewall
```bash
# Allow Azure services
az sql server firewall-rule create \
  --resource-group rg-shared-poc \
  --server sql-poc-shared \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow your IP (for development)
az sql server firewall-rule create \
  --resource-group rg-shared-poc \
  --server sql-poc-shared \
  --name AllowMyIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>
```

### 3. Create Free Databases

**Option A: Azure Portal**
1. Visit [Azure SQL Hub](https://aka.ms/azuresqlhub)
2. Click "Try for free" link
3. Select your logical server
4. Verify free offer banner appears
5. Complete creation with defaults

**Option B: Azure CLI** (verify free tier in portal first)
```bash
az sql db create \
  --resource-group rg-shared-poc \
  --server sql-poc-shared \
  --name db-aspire-app \
  --edition GeneralPurpose \
  --compute-model Serverless \
  --family Gen5 \
  --capacity 1 \
  --auto-pause-delay 60
```

### 4. Get Connection Strings
```bash
az sql db show-connection-string \
  --client ado.net \
  --server sql-poc-shared \
  --name db-aspire-app
```

## Monitoring Free Tier Usage

### Azure Portal
1. Navigate to database **Overview** page
2. Check **Free monthly vCore amount** widget
3. Shows vCore seconds remaining for current month

### Create Alert (Recommended)
Set up alert when 90% of free compute is consumed:
```bash
az monitor metrics alert create \
  --name FreeComputeLowAlert \
  --resource-group rg-shared-poc \
  --scopes <database-resource-id> \
  --condition "Free amount remaining < 10000" \
  --description "Free tier compute nearly exhausted"
```

### Metrics to Track
- **Free amount remaining** (vCore seconds)
- **Free amount consumed** (vCore seconds)
- **app_cpu_billed** (actual billing metric)

## Use Cases for This Workspace

### .NET Aspire Application
- **Main database:** Application data, user state
- **Cost:** Free (intermittent usage pattern)
- **Size:** Well within 32 GB for POC

### Polymarket Clone
- **Database:** Bets, users, market outcomes
- **Cost:** Free (read-heavy, occasional writes)
- **Size:** Easily fits in 32 GB

### Background Workers
- **Database:** Job state, message deduplication
- **Cost:** Free (low-frequency state updates)
- **Size:** Minimal storage needs

### MCP Server
- **Database:** Context storage, session state
- **Cost:** Free (burst usage, auto-pause friendly)
- **Size:** Small footprint

### Static Web Apps Backend
- **Database:** API data persistence
- **Cost:** Free (serverless aligns with SWA free tier)
- **Size:** POC data volumes

## Tips for Staying Within Free Limits

### 1. Disconnect Tools When Idle
- Close SQL Server Management Studio object explorer
- Disconnect IDE database connections
- Prevents accidental compute consumption

### 2. Optimize Auto-Pause
```sql
-- Set auto-pause delay (minutes of inactivity)
-- Default: 60 minutes
-- Minimum: 60 minutes
-- Disable: -1 (but watch costs!)
```

### 3. Batch Operations
- Group database operations together
- Minimize wake-ups from paused state
- Use background jobs for batch processing

### 4. Use Efficient Queries
- Index properly to reduce compute time
- Avoid full table scans
- Monitor query performance

### 5. Development Practices
- Use local SQL Express/LocalDB for development
- Reserve cloud database for testing/demos
- Reduces compute consumption significantly

## Troubleshooting

### Free Offer Not Appearing
1. Verify subscription type (works with all except Students Starter)
2. Check if 10 database limit already reached
3. Select server explicitly in dropdown
4. Try different region if first time creating

### Database Paused Unexpectedly
- Check vCore consumption metrics
- Verify auto-pause setting
- Review alert history
- Consider switching to "continue with charges" if needed

### Cannot Connect
1. Verify firewall rules include your IP
2. Check if database is paused (will auto-resume on connect)
3. Confirm connection string credentials
4. Test from Azure Portal Query Editor first

## Related Documentation

- [Azure SQL Database Pricing](https://azure.microsoft.com/pricing/details/azure-sql-database/single/)
- [Serverless Compute Tier Overview](https://learn.microsoft.com/azure/azure-sql/database/serverless-tier-overview)
- [Free Offer FAQ](https://learn.microsoft.com/azure/azure-sql/database/free-offer-faq)

## Changelog

- **2026-01-13:** Initial documentation created with free tier details and multi-database architecture guidance
