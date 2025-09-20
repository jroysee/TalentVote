# TalentVote

A creative community platform for artist selection and cultural event programming built on the Stacks blockchain using Clarity smart contracts.

## Overview

TalentVote enables artists to register their profiles, event organizers to create voting events, and communities to democratically select artists for cultural events. The platform features a decentralized voting system with STX-based fees and prize pools.

## Features

- **Artist Registration**: Artists can register with detailed profiles including name, bio, genre, and portfolio
- **Event Creation**: Event organizers can create voting events with customizable parameters
- **Democratic Voting**: Community members can vote for their preferred artists in events
- **Prize Pools**: Support for STX-based prize pools that can be funded by the community
- **Fee Structure**: Platform fees for artist registration and event creation
- **Time-bound Voting**: Events have defined voting periods with automatic closure
- **Artist Participation**: Artists can register for specific events they want to participate in

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.5
- **Smart Contract**: TalentVote.clar
- **Testing Framework**: Vitest with Clarinet SDK
- **Development Tools**: Clarinet, TypeScript

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v18 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd TalentVote
```

2. Navigate to the contract directory:
```bash
cd TalentVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Artist Registration

```clarity
;; Register as an artist (costs 1 STX)
(contract-call? .TalentVote register-artist
  "Artist Name"
  "Passionate musician creating innovative soundscapes"
  "Electronic"
  "https://portfolio.example.com")
```

### Creating an Event

```clarity
;; Create a voting event (costs 2 STX)
(contract-call? .TalentVote create-event
  "Summer Music Festival 2024"
  "Annual summer festival featuring emerging electronic artists"
  "Central Park, NYC"
  u1640995200  ;; Event date (Unix timestamp)
  u144         ;; Voting duration (blocks)
  u10)         ;; Maximum artists
```

### Voting for an Artist

```clarity
;; Vote for an artist in an event
(contract-call? .TalentVote vote-for-artist
  u1    ;; event-id
  u1    ;; artist-id
  u100) ;; vote-weight
```

### Adding to Prize Pool

```clarity
;; Add STX to event prize pool
(contract-call? .TalentVote add-prize-pool
  u1        ;; event-id
  u1000000) ;; amount in microSTX (1 STX)
```

## Contract Functions Documentation

### Public Functions

#### Artist Management
- `register-artist(name, bio, genre, portfolio-url)` - Register a new artist profile
- `update-artist(artist-id, name, bio, genre, portfolio-url)` - Update existing artist profile
- `register-for-event(artist-id, event-id)` - Register artist for specific event

#### Event Management
- `create-event(title, description, location, event-date, voting-duration, max-artists)` - Create new voting event
- `finalize-event(event-id)` - Close voting and finalize event (creator only)
- `add-prize-pool(event-id, amount)` - Add STX to event prize pool

#### Voting
- `vote-for-artist(event-id, artist-id, vote-weight)` - Cast vote for artist in event

#### Administrative
- `set-platform-fee(new-fee)` - Update platform fee (owner only)
- `deactivate-artist(artist-id)` - Deactivate artist profile (owner only)

### Read-Only Functions

- `get-artist(artist-id)` - Retrieve artist profile
- `get-event(event-id)` - Retrieve event details
- `get-artist-event-status(artist-id, event-id)` - Check artist registration status
- `get-vote(voter, event-id, artist-id)` - Get specific vote details
- `has-user-voted(voter, event-id)` - Check if user has voted in event
- `get-next-artist-id()` - Get next available artist ID
- `get-next-event-id()` - Get next available event ID
- `get-platform-fee()` - Get current platform fee
- `is-voting-open(event-id)` - Check if voting is still active for event

### Error Codes

- `u100` - Owner only operation
- `u101` - Resource not found
- `u102` - Resource already exists
- `u103` - Unauthorized access
- `u104` - Invalid input parameters
- `u105` - Voting period closed
- `u106` - User already voted
- `u107` - Insufficient balance

## Data Structures

### Artist Profile
```clarity
{
  owner: principal,
  name: (string-ascii 50),
  bio: (string-ascii 500),
  genre: (string-ascii 30),
  portfolio-url: (string-ascii 200),
  created-at: uint,
  total-votes: uint,
  is-active: bool
}
```

### Event
```clarity
{
  creator: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  location: (string-ascii 100),
  event-date: uint,
  voting-end: uint,
  max-artists: uint,
  selected-artists: (list 20 uint),
  total-votes: uint,
  prize-pool: uint,
  is-active: bool
}
```

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage and cost analysis:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## Deployment Guide

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract TalentVote
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deployment generate --testnet
clarinet deployment apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deployment generate --mainnet
clarinet deployment apply --mainnet
```

## Security Considerations

### Access Controls
- Contract owner has administrative privileges
- Artists can only modify their own profiles
- Event creators can finalize their own events
- Users can only vote once per event

### Financial Security
- Platform fees are transferred to contract owner
- Prize pools are held in contract escrow
- STX transfers use built-in Clarity functions
- Input validation prevents zero or negative amounts

### Data Integrity
- Immutable voting records
- Time-bound voting periods
- Artist registration verification
- Event participation tracking

### Best Practices
- Always validate input parameters
- Check voting period status before allowing votes
- Verify artist registration before voting
- Use proper error handling for all operations

## Fee Structure

- **Artist Registration**: 1 STX (1,000,000 microSTX)
- **Event Creation**: 2 STX (2,000,000 microSTX)
- **Voting**: Free (no fees)
- **Prize Pool Contributions**: User-defined amounts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please create an issue in the repository or contact the development team.