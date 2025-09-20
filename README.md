# CorporateChoice

A blockchain platform for takeover bids and strategic partnership approvals built on the Stacks blockchain using Clarity smart contracts.

## Overview

CorporateChoice enables transparent, decentralized corporate governance by facilitating takeover bids, strategic partnerships, and voting mechanisms for corporate decisions. The platform ensures that all stakeholders can participate in critical business decisions through a secure, immutable voting system.

## Features

### Core Functionality
- **Company Registration**: Register companies with market cap, share information, and ownership details
- **Takeover Bid Management**: Create and manage both friendly and hostile takeover bids
- **Strategic Partnership Proposals**: Propose mergers, acquisitions, joint ventures, and strategic alliances
- **Shareholder Voting**: Weighted voting system based on shareholding percentages
- **Proposal Management**: Time-bound proposals with automatic expiration
- **Vote Finalization**: Democratic decision-making with configurable approval thresholds

### Security Features
- **Access Control**: Role-based permissions for company owners and shareholders
- **Duplicate Prevention**: Protection against double voting and duplicate proposals
- **Time Constraints**: Automatic expiration of bids and proposals
- **Validation**: Comprehensive input validation and error handling

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Contract File**: `contracts/CorporateChoice.clar`

### Data Structures

#### Companies
- Company ID, name, owner, market cap
- Outstanding shares and public status
- Creation timestamp

#### Takeover Bids
- Bidder, target company, offer details
- Bid type (friendly/hostile)
- Status tracking and voting results
- Time-based expiration

#### Partnership Proposals
- Proposer and involved companies
- Proposal type and terms
- Approval thresholds and voting results
- Status management

#### Shareholder Management
- Share ownership tracking
- Voting power calculation
- Voting history maintenance

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- [Node.js](https://nodejs.org/) (for development tools)
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/cli) (optional)

### Setup
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd CorporateChoice
   ```

2. Install dependencies:
   ```bash
   cd CorporateChoice_contract
   npm install
   ```

3. Verify installation:
   ```bash
   clarinet check
   ```

## Usage Examples

### Company Registration
```clarity
;; Register a new company
(contract-call? .CorporateChoice register-company
  "TechCorp"
  u1000000000  ;; $1B market cap
  u100000000   ;; 100M shares outstanding
  true)        ;; public company
```

### Creating a Takeover Bid
```clarity
;; Create a friendly takeover bid
(contract-call? .CorporateChoice create-takeover-bid
  u1           ;; target company ID
  u1200000000  ;; $1.2B offer amount
  u12          ;; $12 per share
  "friendly"   ;; bid type
  u1440)       ;; expires in 1440 blocks (~10 days)
```

### Partnership Proposal
```clarity
;; Propose a merger between two companies
(contract-call? .CorporateChoice create-partnership-proposal
  u1                    ;; company A
  u2                    ;; company B
  "merger"              ;; proposal type
  "50-50 merger terms"  ;; terms description
  u2880                 ;; expires in 2880 blocks (~20 days)
  u75)                  ;; requires 75% approval
```

### Voting on Proposals
```clarity
;; Vote in favor of a takeover bid
(contract-call? .CorporateChoice vote-on-bid u1 true)

;; Vote against a partnership proposal
(contract-call? .CorporateChoice vote-on-proposal u1 false)
```

## Contract Functions

### Public Functions

#### Company Management
- `register-company(name, market-cap, shares-outstanding, is-public)` - Register a new company
- `update-contract-owner(new-owner)` - Update contract ownership (admin only)

#### Takeover Bids
- `create-takeover-bid(target-company, offer-amount, price-per-share, bid-type, duration-blocks)` - Create a takeover bid
- `vote-on-bid(bid-id, vote)` - Vote on a takeover bid
- `finalize-bid(bid-id)` - Finalize bid results

#### Partnership Proposals
- `create-partnership-proposal(company-a, company-b, proposal-type, terms, duration-blocks, required-approval-percentage)` - Create partnership proposal
- `vote-on-proposal(proposal-id, vote)` - Vote on a partnership proposal
- `finalize-proposal(proposal-id)` - Finalize proposal results

### Read-Only Functions

#### Data Retrieval
- `get-company(company-id)` - Get company information
- `get-takeover-bid(bid-id)` - Get takeover bid details
- `get-partnership-proposal(proposal-id)` - Get partnership proposal details
- `get-shareholder-info(company-id, shareholder)` - Get shareholder information
- `get-bid-vote(bid-id, voter)` - Get voting record for bid
- `get-proposal-vote(proposal-id, voter)` - Get voting record for proposal

#### System Information
- `get-next-company-id()` - Get next available company ID
- `get-next-bid-id()` - Get next available bid ID
- `get-next-proposal-id()` - Get next available proposal ID

## Error Codes

The contract defines comprehensive error handling:

- `ERR-NOT-AUTHORIZED (100)` - Insufficient permissions
- `ERR-COMPANY-NOT-FOUND (101)` - Company does not exist
- `ERR-COMPANY-EXISTS (102)` - Company already exists
- `ERR-BID-NOT-FOUND (103)` - Takeover bid not found
- `ERR-BID-EXISTS (104)` - Bid already exists
- `ERR-BID-EXPIRED (105)` - Bid has expired
- `ERR-BID-NOT-ACTIVE (106)` - Bid is not active
- `ERR-INSUFFICIENT-AMOUNT (107)` - Amount too low
- `ERR-ALREADY-VOTED (108)` - User already voted
- `ERR-PROPOSAL-NOT-FOUND (109)` - Proposal not found
- `ERR-PROPOSAL-EXPIRED (110)` - Proposal has expired
- `ERR-INVALID-PERCENTAGE (111)` - Invalid percentage value

## Deployment Guide

### Local Development
1. Start Clarinet console:
   ```bash
   clarinet console
   ```

2. Deploy contract:
   ```clarity
   ::get_contracts
   ```

### Testnet Deployment
1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
   ```bash
   clarinet deployments generate --testnet
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment
1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
   ```bash
   clarinet deployments generate --mainnet
   clarinet deployments apply --mainnet
   ```

## Security Considerations

### Access Control
- Company owners have exclusive rights to certain operations
- Shareholders can only vote on companies where they hold shares
- Contract owner has administrative privileges

### Validation
- All inputs are validated for type and range
- Duplicate votes are prevented
- Time-based expiration prevents stale proposals

### Best Practices
- Use time-locked proposals for important decisions
- Implement proper shareholder verification
- Regular security audits recommended
- Monitor for unusual voting patterns

### Known Limitations
- Fixed voting power calculation (percentage-based)
- No built-in dispute resolution mechanism
- Time measurements based on block height
- No partial bid acceptance mechanism

## Development

### Project Structure
```
CorporateChoice_contract/
├── contracts/
│   └── CorporateChoice.clar    # Main smart contract
├── settings/
│   ├── Devnet.toml            # Development network config
│   ├── Testnet.toml           # Testnet configuration
│   └── Mainnet.toml           # Mainnet configuration
├── Clarinet.toml              # Project configuration
├── package.json               # Node.js dependencies
└── tsconfig.json              # TypeScript configuration
```

### Testing
Run contract tests using Clarinet:
```bash
clarinet test
```

### Code Quality
The contract includes:
- Comprehensive error handling
- Input validation
- Access control mechanisms
- Clear documentation
- Consistent naming conventions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Please review the license file for specific terms and conditions.

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or contact the development team.