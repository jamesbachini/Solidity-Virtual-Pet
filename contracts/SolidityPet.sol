// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SolidityPet {
    struct Pet {
        string name;
        uint256 hunger;
        uint256 happiness;
        uint256 lastInteraction;
        uint256 lastHungerUpdate;
    }

    mapping(address => Pet) public pets;
    address[] public petOwners;

    uint256 public constant MAX_PETS = 10000;
    uint256 public constant MAX_HUNGER = 100;
    uint256 public constant MAX_HAPPINESS = 100;
    uint256 public constant HUNGER_RATE = 1;
    uint256 public constant JEALOUS_RATE = 1;

    event PetCreated(address owner, string name);
    event PetFed(address owner, uint256 newHunger);
    event PetPlayed(address owner, uint256 newHappiness);

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function createPet(string memory _name) public {
        require(petOwners.length < MAX_PETS, "All pets minted");
        require(pets[msg.sender].lastInteraction == 0, "You already have a pet");
        pets[msg.sender] = Pet(_name, 50, 50, block.timestamp, block.timestamp);
        petOwners.push(msg.sender);
        emit PetCreated(msg.sender, _name);
    }

    function updateHunger(address _owner) private {
        Pet storage pet = pets[_owner];
        uint256 hoursPassed = (block.timestamp - pet.lastHungerUpdate) / 1 hours;
        if (hoursPassed > 0) {
            pet.hunger = min(pet.hunger + hoursPassed * HUNGER_RATE, MAX_HUNGER);
            pet.lastHungerUpdate = block.timestamp;
        }
    }

    function feedPet() public {
        Pet storage pet = pets[msg.sender];
        require(pet.lastInteraction > 0, "You don't have a pet");
        require(block.timestamp - pet.lastInteraction >= 1 minutes, "You can only interact once per minute");
        updateHunger(msg.sender);
        if (pet.hunger >= 10) {
            pet.hunger -= 10;
        } else {
            pet.hunger = 0;
        }
        pet.lastInteraction = block.timestamp;
        emit PetFed(msg.sender, pet.hunger);
    }

    function playWithPet() public {
        Pet storage pet = pets[msg.sender];
        require(pet.lastInteraction > 0, "You don't have a pet");
        require(block.timestamp - pet.lastInteraction >= 1 minutes, "You can only interact once per minute");
        updateHunger(msg.sender);
        if (pet.happiness <= 90) {
            pet.happiness += 10;
        } else {
            pet.happiness = 100;
        }
        for (uint i = 0; i < petOwners.length; i++) {
            if (petOwners[i] != msg.sender) {
                Pet storage otherPet = pets[petOwners[i]];
                if (otherPet.happiness >= JEALOUS_RATE) {
                    otherPet.happiness -= JEALOUS_RATE;
                } else {
                    otherPet.happiness = 0;
                }
            }
        }
        pet.lastInteraction = block.timestamp;
        emit PetPlayed(msg.sender, pet.happiness);
    }

    function getPetStatus(address _owner) public view returns (string memory name, uint256 hunger, uint256 happiness) {
        Pet storage pet = pets[_owner];
        require(pet.lastInteraction > 0, "This address doesn't have a pet");
        uint256 currentHunger = pet.hunger;
        uint256 hoursPassed = (block.timestamp - pet.lastHungerUpdate) / 1 hours;
        if (hoursPassed > 0) {
            currentHunger = min(pet.hunger + hoursPassed * HUNGER_RATE, MAX_HUNGER);
        }
        return (pet.name, currentHunger, pet.happiness);
    }
}