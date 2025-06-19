# ZK Panagram Game Design Document

## Core Game Concept

The game revolves around **answers** (e.g., specific words), where each correct answer defines a **round**.

- Each "answer" corresponds to a unique round.
- Rounds are designed to be continuous.
- Only the **contract owner** can initiate a new round.

## Owner's Role and Responsibilities

- A designated **smart contract owner** will be responsible for managing the game.
- Only this owner is authorized to **start a new round**.

## Round Mechanics and Rules

- **Minimum Duration**:  
  Each round must last for a **predefined minimum duration**.

- **Starting New Rounds**:  
  A new round can only be initiated if the **previous round has concluded** with a declared winner.

- **Determining the Winner**:  
  The **first user** to submit the correct guess for the round's answer is declared the **winner**.

- **Runners-Up**:  
  Other users who submit correct guesses **after the winner** are acknowledged as **runners-up**.

## NFT Contract (ERC-1155 Standard)

The main `Panagram` smart contract will use the **ERC-1155** token standard to manage semi-fungible tokens.

- **Token ID 0**:  
  Minted and awarded to the **winners** of each round.

- **Token ID 1**:  
  Minted and awarded to the **runners-up** of each round.

## Token Minting Logic

- **Token ID 0 (Winner's Token)**:  
  Minted exclusively to the **first correct guesser** in a round.

- **Token ID 1 (Runner-Up Token)**:  
  Minted to users who guessed correctly but **were not first**.

## Verifier Smart Contract Integration

- The `Panagram` contract will **delegate answer verification** to a separate **Verifier smart contract**.
- The **Verifier contract's address** must be provided to the `Panagram` contract **during deployment** via its constructor.
