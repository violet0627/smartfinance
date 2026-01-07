# Investment Portfolio Tracking Guide

## Overview
The SmartFinance app now includes a comprehensive **Investment Portfolio Tracking** system that allows users to manually track their investments across different asset types, monitor performance, and calculate profit/loss in real-time.

---

## Features

### 1. Multi-Asset Type Support
Track 10 different types of investments:
- **Stocks**: Company shares and equities
- **Cryptocurrency**: Bitcoin, Ethereum, and other digital currencies
- **Bonds**: Government and corporate bonds
- **Mutual Funds**: Professionally managed investment funds
- **ETF**: Exchange-traded funds
- **Real Estate**: Property investments
- **Commodities**: Gold, silver, oil, etc.
- **Fixed Deposit**: Fixed deposit accounts
- **Unit Trust**: Malaysian unit trust funds
- **Other**: Any other investment types

### 2. Investment Entry
**Add Investment Screen** allows users to:
- Select asset type with icon-based grid
- Enter asset name (e.g., "Apple Inc.", "Bitcoin")
- Optional stock symbol (e.g., "AAPL", "BTC")
- Specify quantity (shares, units, coins)
- Set purchase price per unit
- Select purchase date
- Optional current price (defaults to purchase price)
- Add notes for additional information

### 3. Portfolio Summary
**Real-time calculations** include:
- **Total Invested**: Sum of all purchase values
- **Current Value**: Sum of all current values
- **Total Profit/Loss**: Current value minus invested amount
- **Percentage Change**: Overall portfolio performance
- **Asset Breakdown**: Performance by asset type
- **Top Performers**: Best performing investments (up to 3)
- **Bottom Performers**: Worst performing investments (up to 3)

### 4. Performance Tracking
**Each investment shows**:
- Current value
- Profit/Loss amount
- Percentage change (color-coded)
- Days held
- Purchase date
- Asset type with icon

### 5. Price Updates
**Quick Price Update**:
- Tap any investment to update current price
- Automatically recalculates profit/loss
- Updates portfolio summary

### 6. Dashboard Integration
**Investment card on dashboard** displays:
- Current portfolio value
- Total profit/loss
- Percentage change with trend icon
- Number of assets
- Quick navigation to full portfolio

---

## How It Works

### Backend API Endpoints

#### 1. Create Investment
```http
POST /api/investments/
```
**Request Body:**
```json
{
  "assetName": "Apple Inc.",
  "assetsType": "Stocks",
  "stockSymbol": "AAPL",
  "quantity": 10,
  "purchasePrice": 150.50,
  "purchaseDate": "2025-01-01",
  "currentPrice": 175.25,
  "notes": "Long-term hold",
  "userId": 1
}
```

#### 2. Get User Investments
```http
GET /api/investments/user/{userId}?type=Stocks
```
Returns all investments with optional filtering by asset type.

#### 3. Get Portfolio Summary
```http
GET /api/investments/user/{userId}/portfolio
```
Returns comprehensive portfolio analysis:
- Total invested and current value
- Profit/loss calculations
- Asset breakdown by type
- Top and bottom performers

#### 4. Update Investment
```http
PUT /api/investments/{investmentId}
```
Update investment details (quantity, current price, notes).

#### 5. Quick Price Update
```http
POST /api/investments/{investmentId}/update-price
```
**Request Body:**
```json
{
  "currentPrice": 180.00
}
```
Returns updated investment with calculated profit/loss.

#### 6. Delete Investment
```http
DELETE /api/investments/{investmentId}
```

---

## User Interface

### Add Investment Screen
**Visual asset type selection**:
- 3-column grid with icon cards
- Color-coded icons for each asset type
- Selected type highlighted with colored background
- Clear, intuitive form layout

**Form Fields**:
1. Asset Type (required) - Grid selection
2. Asset Name (required) - Text input
3. Stock Symbol (optional) - Text input
4. Quantity (required) - Decimal number
5. Purchase Price (required) - Currency input
6. Purchase Date (required) - Date picker
7. Current Price (optional) - Currency input
8. Notes (optional) - Multi-line text

### Portfolio Overview Screen
**Summary Card** (gradient background):
- Large portfolio value display
- Invested vs Profit/Loss comparison
- Percentage change with icon
- Visual hierarchy

**Asset Breakdown Section**:
- Card for each asset type held
- Shows count, current value, and performance
- Color-coded performance indicators

**Top Performers Section**:
- Highlights best 3 investments
- Shows percentage gain and amount
- Asset type icon and name

**Investment List**:
- All investments displayed as cards
- Swipe-to-delete functionality
- Tap to update price
- Shows days held and performance

### Dashboard Investment Card
**Compact summary** showing:
- Portfolio title with performance badge
- Current value (large, bold)
- Total profit/loss
- Total invested and asset count
- Trend icon (up/down/flat)
- Tap to navigate to full portfolio

---

## Calculation Logic

### Purchase Value
```dart
purchaseValue = quantity × purchasePrice
```

### Current Value
```dart
currentValue = quantity × (currentPrice ?? purchasePrice)
```

### Profit/Loss
```dart
profitLoss = currentValue - purchaseValue
```

### Percentage Change
```dart
percentageChange = (profitLoss / purchaseValue) × 100
```

### Portfolio Totals
```dart
totalInvested = sum(all purchaseValues)
totalCurrentValue = sum(all currentValues)
totalProfitLoss = totalCurrentValue - totalInvested
overallPercentage = (totalProfitLoss / totalInvested) × 100
```

### Asset Breakdown
For each asset type:
```dart
typeInvested = sum(purchaseValues for type)
typeCurrentValue = sum(currentValues for type)
typeProfitLoss = typeCurrentValue - typeInvested
typePercentage = (typeProfitLoss / typeInvested) × 100
```

---

## Color Coding

### Performance Colors
- **Green** (`#4CAF50`): Positive performance (profit)
- **Red** (`#E53935`): Negative performance (loss)
- **Grey** (`#9E9E9E`): No change

### Trend Icons
- **Trending Up** (↗): Positive percentage change
- **Trending Down** (↘): Negative percentage change
- **Trending Flat** (→): Zero change

---

## Usage Examples

### Example 1: Adding a Stock Investment
1. Navigate to Portfolio Overview
2. Tap **+** button
3. Select **Stocks** from grid
4. Enter "Apple Inc." as asset name
5. Enter "AAPL" as stock symbol
6. Enter quantity: 10
7. Enter purchase price: RM 150.50
8. Select purchase date
9. Tap **Add Investment**

**Result**: Investment added with purchase value of RM 1,505.00

### Example 2: Updating Price
1. Open Portfolio Overview
2. Find the Apple Inc. investment
3. Tap the investment card
4. Enter new current price: RM 175.25
5. Tap **Update**

**Result**:
- Profit/Loss: RM 247.50
- Percentage Change: +16.4%
- Portfolio summary updated

### Example 3: Portfolio Analysis
**User has**:
- 10 shares AAPL @ RM 175.25 (bought @ RM 150.50)
- 0.5 BTC @ RM 200,000 (bought @ RM 180,000)
- 1000g Gold @ RM 280/g (bought @ RM 250/g)

**Portfolio Summary**:
- Total Invested: RM 433,505.00
- Current Value: RM 482,752.50
- Total Profit: RM 49,247.50
- Percentage Change: +11.36%

**Asset Breakdown**:
- Stocks: +16.4% (RM 247.50)
- Cryptocurrency: +11.1% (RM 10,000.00)
- Commodities: +12.0% (RM 30,000.00)

---

## Best Practices

### For Users

1. **Regular Price Updates**
   - Update prices weekly or monthly
   - Keep track of volatile assets (crypto, stocks)
   - Set reminders for periodic updates

2. **Accurate Data Entry**
   - Enter exact purchase prices
   - Include all transaction costs in purchase price
   - Use stock symbols for easier tracking

3. **Diversification Tracking**
   - Monitor asset breakdown
   - Aim for balanced portfolio
   - Identify overconcentration

4. **Performance Review**
   - Check top/bottom performers
   - Rebalance based on performance
   - Make informed decisions

5. **Use Notes Field**
   - Record investment thesis
   - Note important dates (dividend dates, maturity)
   - Track rationale for future reference

### For Developers

1. **Data Integrity**
   - Validate all numeric inputs
   - Prevent negative quantities or prices
   - Handle edge cases (zero values, very large numbers)

2. **Performance Optimization**
   - Cache portfolio calculations
   - Lazy load investment list
   - Optimize database queries

3. **User Experience**
   - Clear error messages
   - Loading states during calculations
   - Smooth animations for updates

4. **Future Enhancements**
   - Auto-fetch prices from APIs
   - Charts for performance visualization
   - Multiple currency support
   - Export to CSV/PDF

---

## Technical Implementation

### Models

**InvestmentModel** (`lib/models/investment_model.dart`):
```dart
class InvestmentModel {
  final String assetName;
  final String assetsType;
  final double quantity;
  final double purchasePrice;
  final DateTime purchaseDate;
  final double? currentPrice;

  // Computed properties
  double get purchaseValue;
  double get currentValue;
  double get profitLoss;
  double get percentageChange;
  bool get isProfit;
  int get daysHeld;
}
```

**PortfolioSummary** (`lib/models/investment_model.dart`):
```dart
class PortfolioSummary {
  final double totalInvested;
  final double currentValue;
  final double totalProfitLoss;
  final double percentageChange;
  final List<AssetBreakdown> assetBreakdown;
  final List<InvestmentPerformance> topPerformers;
  final List<InvestmentPerformance> bottomPerformers;
  final int totalAssets;
}
```

### Screens

1. **AddInvestmentScreen** - Investment entry form
2. **PortfolioOverviewScreen** - Full portfolio view
3. **DashboardScreen** - Portfolio card integration

### Services

**ApiService** (`lib/services/api_service.dart`):
- `createInvestment()`
- `getUserInvestments()`
- `getPortfolioSummary()`
- `updateInvestment()`
- `updateInvestmentPrice()`
- `deleteInvestment()`

### Utils

**InvestmentTypes** (`lib/utils/investment_types.dart`):
- Asset type definitions with icons and colors
- Performance color coding
- Helper methods for UI

---

## Future Enhancements

### 1. Automatic Price Updates
- Integration with financial APIs (Alpha Vantage, Yahoo Finance)
- Real-time price fetching
- Scheduled background updates
- Push notifications for significant changes

### 2. Performance Charts
- Line charts for portfolio value over time
- Pie charts for asset allocation
- Bar charts for profit/loss by asset
- Time range selection (1M, 3M, 6M, 1Y, ALL)

### 3. Advanced Analytics
- Dividend tracking and yield calculation
- Annualized returns
- Risk metrics (volatility, Sharpe ratio)
- Portfolio rebalancing suggestions

### 4. Transaction History
- Track all buy/sell transactions
- Calculate average cost basis
- Realized vs unrealized gains
- Tax reporting support

### 5. Multi-Currency Support
- Track investments in different currencies
- Auto currency conversion
- Exchange rate tracking
- Base currency setting

### 6. Watchlist
- Add assets to watchlist without purchasing
- Monitor potential investments
- Price alerts for watchlist items

### 7. Export and Reporting
- PDF portfolio reports
- CSV export for Excel analysis
- Email periodic reports
- Performance summaries

---

## Summary

The Investment Portfolio Tracking system provides SmartFinance users with a powerful tool to:
- **Track** multiple investment types in one place
- **Monitor** real-time performance and profit/loss
- **Analyze** portfolio composition and top performers
- **Update** prices manually as needed
- **Make** informed investment decisions

The system is fully integrated with the dashboard for quick access and provides detailed views for in-depth analysis. With support for 10 asset types, comprehensive calculations, and intuitive UI, users can effectively manage their investment portfolio alongside their budgets and transactions.

**Next Steps**: Consider implementing automatic price updates and performance charts to enhance the investment tracking experience further!
