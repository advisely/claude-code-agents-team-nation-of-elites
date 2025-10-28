---
name: crypto-defi-patterns
description: Cryptocurrency trading, DeFi protocols, smart contract interaction, blockchain integration, and crypto API development
---

# Cryptocurrency & DeFi Development Patterns

## When to Use This Skill

- Building cryptocurrency trading systems
- Integrating with DeFi protocols
- Interacting with smart contracts
- Developing crypto wallets
- Building blockchain applications

## Target Agents

- `crypto-api-developer` - Primary user
- `backend-developer` - Crypto backend systems
- `financial-systems-expert` - Crypto trading

## Core Patterns

### 1. Web3 Integration with ethers.js

```typescript
import { ethers } from 'ethers'

class Web3Service {
  private provider: ethers.providers.Provider
  private signer: ethers.Signer

  constructor(rpcUrl: string, privateKey: string) {
    this.provider = new ethers.providers.JsonRpcProvider(rpcUrl)
    this.signer = new ethers.Wallet(privateKey, this.provider)
  }

  async getBalance(address: string): Promise<string> {
    const balance = await this.provider.getBalance(address)
    return ethers.utils.formatEther(balance)
  }

  async sendTransaction(to: string, amount: string) {
    const tx = await this.signer.sendTransaction({
      to,
      value: ethers.utils.parseEther(amount)
    })

    const receipt = await tx.wait()
    return receipt
  }
}
```

### 2. Smart Contract Interaction

```typescript
interface IUniswapV2Router {
  swapExactTokensForTokens(
    amountIn: BigNumber,
    amountOutMin: BigNumber,
    path: string[],
    to: string,
    deadline: number
  ): Promise<ContractTransaction>
}

class DeFiService {
  private router: IUniswapV2Router

  constructor(routerAddress: string, signer: Signer) {
    this.router = new ethers.Contract(
      routerAddress,
      UNISWAP_ROUTER_ABI,
      signer
    ) as IUniswapV2Router
  }

  async swapTokens(
    tokenIn: string,
    tokenOut: string,
    amountIn: string,
    slippage: number = 0.5
  ) {
    const path = [tokenIn, tokenOut]
    const amountInWei = ethers.utils.parseEther(amountIn)

    // Calculate minimum output with slippage
    const amountOut = await this.getAmountOut(amountInWei, path)
    const amountOutMin = amountOut.mul(100 - slippage).div(100)

    const deadline = Math.floor(Date.now() / 1000) + 60 * 20 // 20 minutes

    const tx = await this.router.swapExactTokensForTokens(
      amountInWei,
      amountOutMin,
      path,
      await this.signer.getAddress(),
      deadline
    )

    return await tx.wait()
  }
}
```

### 3. Wallet Management

```typescript
import { HDNode } from 'ethers/lib/utils'

class WalletService {
  generateMnemonic(): string {
    return ethers.Wallet.createRandom().mnemonic.phrase
  }

  deriveWallet(mnemonic: string, index: number = 0): ethers.Wallet {
    const path = `m/44'/60'/0'/0/${index}` // BIP44 Ethereum path
    return ethers.Wallet.fromMnemonic(mnemonic, path)
  }

  async signMessage(wallet: ethers.Wallet, message: string): Promise<string> {
    return await wallet.signMessage(message)
  }
}
```

### 4. Exchange API Integration

```typescript
import ccxt from 'ccxt'

class ExchangeService {
  private exchange: ccxt.Exchange

  constructor(exchangeName: string, apiKey: string, secret: string) {
    const ExchangeClass = ccxt[exchangeName]
    this.exchange = new ExchangeClass({
      apiKey,
      secret,
    })
  }

  async fetchBalance() {
    return await this.exchange.fetchBalance()
  }

  async placeOrder(
    symbol: string,
    type: 'market' | 'limit',
    side: 'buy' | 'sell',
    amount: number,
    price?: number
  ) {
    return await this.exchange.createOrder(symbol, type, side, amount, price)
  }

  async fetchOrderBook(symbol: string, limit: number = 20) {
    return await this.exchange.fetchOrderBook(symbol, limit)
  }
}
```

## Best Practices

1. **Use testnet for development**
2. **Implement proper key management**
3. **Handle gas fees appropriately**
4. **Implement transaction retry logic**
5. **Monitor blockchain confirmations**
6. **Validate addresses before transactions**
7. **Implement rate limiting for APIs**
8. **Use hardware wallets for production**
9. **Implement proper error handling**
10. **Audit smart contract interactions**
