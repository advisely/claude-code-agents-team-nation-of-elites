---
name: financial-trading-patterns
description: Algorithmic trading patterns, risk management, order execution, backtesting, and financial systems development
---

# Financial Trading System Patterns

## When to Use This Skill

- Building algorithmic trading systems
- Implementing risk management
- Creating order execution engines
- Backtesting trading strategies
- Building fintech applications

## Target Agents

- `financial-systems-expert` - Primary user
- `backend-developer` - Trading system backend
- `data-scientist` - Strategy development

## Core Patterns

### 1. Order Management System

```python
from enum import Enum
from dataclasses import dataclass
from decimal import Decimal
import uuid

class OrderSide(Enum):
    BUY = "BUY"
    SELL = "SELL"

class OrderType(Enum):
    MARKET = "MARKET"
    LIMIT = "LIMIT"
    STOP = "STOP"
    STOP_LIMIT = "STOP_LIMIT"

@dataclass
class Order:
    id: str
    symbol: str
    side: OrderSide
    type: OrderType
    quantity: Decimal
    price: Decimal | None
    stop_price: Decimal | None
    timestamp: int

class OrderManagementSystem:
    def __init__(self):
        self.pending_orders = {}
        self.filled_orders = {}

    def place_order(self, order: Order) -> str:
        """Place a new order"""
        order.id = str(uuid.uuid4())
        self.pending_orders[order.id] = order

        # Send to exchange
        self.send_to_exchange(order)

        return order.id

    def cancel_order(self, order_id: str) -> bool:
        """Cancel a pending order"""
        if order_id in self.pending_orders:
            # Send cancel request to exchange
            del self.pending_orders[order_id]
            return True
        return False
```

### 2. Risk Management

```python
from typing import Dict
from decimal import Decimal

class RiskManager:
    def __init__(
        self,
        max_position_size: Decimal,
        max_portfolio_risk: Decimal,
        max_drawdown: Decimal
    ):
        self.max_position_size = max_position_size
        self.max_portfolio_risk = max_portfolio_risk
        self.max_drawdown = max_drawdown

        self.positions: Dict[str, Decimal] = {}
        self.peak_value = Decimal('0')
        self.current_value = Decimal('0')

    def can_open_position(
        self,
        symbol: str,
        quantity: Decimal,
        price: Decimal
    ) -> tuple[bool, str]:
        """Check if position can be opened"""

        # Position size check
        position_value = quantity * price
        if position_value > self.max_position_size:
            return False, "Position size exceeds maximum"

        # Concentration risk
        current_position = self.positions.get(symbol, Decimal('0'))
        new_position = current_position + quantity

        if new_position > self.max_position_size:
            return False, "Total position exceeds limit"

        # Drawdown check
        current_drawdown = (self.peak_value - self.current_value) / self.peak_value
        if current_drawdown > self.max_drawdown:
            return False, "Maximum drawdown exceeded"

        return True, "OK"

    def calculate_position_size(
        self,
        account_balance: Decimal,
        risk_per_trade: Decimal,
        entry_price: Decimal,
        stop_loss: Decimal
    ) -> Decimal:
        """Calculate position size based on risk"""

        risk_amount = account_balance * risk_per_trade
        risk_per_share = abs(entry_price - stop_loss)

        position_size = risk_amount / risk_per_share

        return min(position_size, self.max_position_size)
```

### 3. Strategy Backtesting

```python
import pandas as pd
from typing import List

class Backtest:
    def __init__(self, initial_capital: Decimal):
        self.initial_capital = initial_capital
        self.capital = initial_capital
        self.trades: List[Trade] = []
        self.equity_curve = []

    def run(self, strategy, data: pd.DataFrame):
        """Run backtest on historical data"""

        for i in range(len(data)):
            current_bar = data.iloc[i]

            # Generate signal
            signal = strategy.generate_signal(data.iloc[:i+1])

            if signal == 'BUY':
                self.enter_long(current_bar)
            elif signal == 'SELL':
                self.exit_long(current_bar)

            # Track equity
            self.equity_curve.append({
                'timestamp': current_bar['timestamp'],
                'equity': self.capital
            })

    def calculate_metrics(self) -> dict:
        """Calculate performance metrics"""

        returns = pd.Series([t.pnl for t in self.trades])

        total_return = (self.capital - self.initial_capital) / self.initial_capital
        sharpe_ratio = returns.mean() / returns.std() * (252 ** 0.5)
        max_drawdown = self.calculate_max_drawdown()

        win_rate = len([t for t in self.trades if t.pnl > 0]) / len(self.trades)

        return {
            'total_return': total_return,
            'sharpe_ratio': sharpe_ratio,
            'max_drawdown': max_drawdown,
            'win_rate': win_rate,
            'num_trades': len(self.trades)
        }
```

### 4. Market Data Handler

```python
import asyncio
from collections import deque

class MarketDataHandler:
    def __init__(self):
        self.subscribers = []
        self.orderbook = {}

    async def process_tick(self, tick: dict):
        """Process incoming market data"""

        symbol = tick['symbol']

        # Update orderbook
        if symbol not in self.orderbook:
            self.orderbook[symbol] = {
                'bids': deque(maxlen=10),
                'asks': deque(maxlen=10)
            }

        self.orderbook[symbol]['bids'].append({
            'price': tick['bid_price'],
            'size': tick['bid_size']
        })

        # Notify subscribers
        await self.notify_subscribers(tick)

    async def notify_subscribers(self, tick: dict):
        """Notify all subscribers of new data"""
        tasks = [sub(tick) for sub in self.subscribers]
        await asyncio.gather(*tasks)
```

## Best Practices

1. **Implement robust risk management**
2. **Use Decimal for financial calculations**
3. **Log all trades and orders**
4. **Implement circuit breakers**
5. **Test thoroughly with historical data**
6. **Monitor latency and performance**
7. **Implement proper error handling**
8. **Use asynchronous processing**
9. **Comply with regulations**
10. **Implement audit trails**
