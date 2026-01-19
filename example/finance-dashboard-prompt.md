# MoneyWise - Personal Finance Dashboard

Build a beautiful, functional personal finance dashboard that helps users understand their spending, track budgets, and plan for the future. This should feel like a modern fintech app, not a spreadsheet.

## Core Features

### Transaction Management

- **Smart Transaction Entry**: Add transactions with amount, date, category, payee, notes, and optional receipt photo
- **Quick Add**: Press `+` or `n` to open quick add modal (amount + category = fast entry)
- **Transaction Import**: Import from CSV (bank exports), recognize patterns, auto-categorize
- **Recurring Transactions**: Set up recurring income/expenses (rent, salary, subscriptions) with smart detection
- **Split Transactions**: Split single transaction across multiple categories (e.g., "Grocery Store" = food + household)
- **Transaction Search**: Full-text search across all transactions with filters
- **Edit History**: Track all changes with audit trail

### Account Management

- **Multi-Account**: Track multiple accounts (checking, savings, credit cards, investments, cash)
- **Account Types**: Bank accounts, credit cards, loans, investments, retirement, crypto, other
- **Balance History**: Track historical balances, visualize over time
- **Account Sync**: Manual balance entry, or integration APIs (Plaid optional, MVP manual)
- **Net Worth**: Calculate total net worth across all accounts

### Budgeting System

- **Envelope Budgeting**: Assign money to categories (envelopes), track spending against each
- **Zero-Based Budgeting**: Every dollar has a job
- **Rolling Budgets**: Monthly budgets that roll over unspent money
- **Budget Templates**: Save/load budget templates
- **Category Groups**: Group related categories (Food = Dining + Groceries + Coffee)
- **Budget Alerts**: Warning at 80% spent, alert at 100% spent
- **Budget History**: Compare actual vs budgeted each month

### Analytics & Insights

- **Spending Breakdown**: Pie charts, bar charts by category, payee, month
- **Income vs Expense**: Monthly trend showing income - expense = saved
- **Cash Flow**: Income and expense trends over time
- **Sankey Diagram**: Visualize money flow (income → categories → savings)
- **Insights Engine**: Smart insights like "You're spending 30% more on coffee than last month"
- **Anomaly Detection**: Flag unusual spending patterns
- **Trends**: See spending trends over months/years
- **Ratios**: 50/30/20 rule compliance, savings rate, etc.

### Goals & Planning

- **Savings Goals**: Set goals (emergency fund, vacation, new car) with target amounts and dates
- **Goal Progress**: Visual progress bars, projected completion dates
- **Debt Payoff**: Track debts, plan payoff strategies (avalanche vs snowball)
- **Bill Tracking**: Upcoming bills calendar, alerts before due dates
- **Subscription Tracker**: Track all subscriptions, identify unused ones

### Reports & Export

- **Monthly Reports**: PDF reports with charts and summaries
- **Tax Preparation**: Generate tax-deductible expense reports by category
- **Data Export**: Export all data as JSON, CSV, or QFX/OFX for other apps
- **Scheduled Reports**: Email monthly reports automatically (optional)
- **Shareable Reports**: Generate read-only links for shared financial planning

## Technical Requirements

### Stack

- **Single HTML file** with embedded CSS/JS (no framework, no build)
- **Local Storage**: localStorage for data, IndexedDB for receipts/attachments
- **Charts**: Chart.js (inline, bundled) for visualizations
- **PDF Generation**: jsPDF (inline) for reports
- **No external APIs** for MVP - all data local

### UI/UX

- **Modern Design**: Clean, professional fintech aesthetic
- **Dark/Light Mode**: System preference + manual toggle
- **Responsive**: Works on mobile (for quick entry), desktop (for analysis)
- **Dashboard Layout**: Summary cards at top, charts below, detailed data in tables
- **Keyboard Shortcuts**:
  - `+` or `n` = New transaction
  - `/` = Search
  - `b` = Budget view
  - `r` = Reports
  - `g` = Goals
  - `esc` = Close modals

### Performance

- **Load**: Under 200KB, instant load
- **Transactions**: Handle 10,000+ transactions smoothly
- **Charts**: Lazy load charts, animate on scroll
- **Export**: Generate PDF reports in under 5 seconds

### Code Quality

- **Security**: All data encrypted locally (Web Crypto API), no data sent anywhere
- **Accessibility**: WCAG 2.1 AA, screen reader support
- **Privacy**: Explicit privacy policy, no analytics, no tracking
- **Backup**: One-click encrypted backup to file

## Example Usage Scenarios

### Scenario 1: Monthly Budget Review

```
1. Open dashboard, see summary cards: Income $5,200, Expenses $3,800, Saved $1,400
2. Click into Budget view, see all categories with progress bars
3. Notice "Dining Out" at 95% budget, 5 days left in month
4. Click category to see transaction list, identify expensive restaurant trip
5. Adjust remaining budget or note to reduce dining next week
```

### Scenario 2: Quick Expense Entry

```
1. Buy coffee for $4.50, open app on phone
2. Press "+", type "4.50", type "coffee", select "Dining" category, press Enter
3. Transaction recorded instantly, budget circle updates
4. App asks "Was this recurring?" - select "Weekly"
5. Now transaction auto-added every week
```

### Scenario 3: Financial Planning

```
1. Set goal: "Emergency Fund" target $10,000, target date 12 months
2. Current savings: $3,500 in emergency fund account
3. Dashboard shows goal progress: 35% complete, on track
4. See projection: at current savings rate, will reach goal in 8 months
5. Run "What If" scenario: if save $200 more/month, reach goal in 6 months
```

### Scenario 4: Tax Preparation

```
1. Go to Reports > Tax Summary
2. Select tax year
3. Export PDF with all business deductions grouped by category
4. See total deductible amount highlighted
```

## Success Criteria

- [ ] **Beautiful UI**: Looks like a real fintech app, not a tutorial project
- [ ] **Fast Entry**: Can add transactions in under 5 seconds
- [ ] **Accurate Tracking**: Budget vs actual always matches transactions
- [ ] **Good Insights**: Charts and reports are useful, not just decorative
- [ ] **Private**: All data stays local, encrypted at rest
- [ ] **Mobile Friendly**: Can use on phone for transaction entry
- [ ] **No Internet Required**: Full functionality offline
- [ ] **Import/Export**: Can migrate data, backup safely
- [ ] **No Errors**: Zero data corruption, handles edge cases
- [ ] **Helpful**: Tooltips, onboarding, FAQ built-in

## Bonus Features

- [ ] **Multi-Currency**: Support for different currencies
- [ ] **Bill Splitting**: Split expenses with friends (simple version)
- [ ] **Investment Tracking**: Track portfolio value over time
- [ ] **Receipt Scanning**: OCR for receipt scanning (Tesseract.js inline)
- [ ] **Voice Entry**: Dictate transactions
- [ ] **Calendar View**: Calendar showing daily spending
- [ ] **Cash Envelopes**: Physical envelope tracking
- [ ] **Collaboration**: Share budget/spending goals with partner
- [ ] **API**: Expose data via local API for other tools
- [ ] **AI Insights**: LLM-powered spending insights and recommendations
