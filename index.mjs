import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);

const [ accAlice, accBob ] =
  await stdlib.newTestAccounts(2, startingBalance);
console.log('Hello, Alice and Bob!');

console.log('Launching...');
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

console.log('testing nft is being created')
const theNFT = await stdlib.launchToken(accAlice, 'Bibi', 'NFT', {supply: 1})
const niftyParams = {
  nftId: theNFT.id,
  numOfTickets: 10,
}
const OUTCOME = ['Number is not a Match', 'Number is a Match'];

await accBob.tokenAccept(niftyParams.nftId);

const SharedFn = {
  getNum: (numOfTickets) => {
    const num = (Math.floor(Math.random() * numOfTickets) + 1);
    return num;
  },
  seeOutcome: (num) => {
    console.log(`Outcome: ${OUTCOME[num]}`);
  },
}

console.log('Starting backends...');
await Promise.all([
  backend.Alice(ctcAlice, {
    ...stdlib.hasRandom,
    ...SharedFn,
    startRaffle: () => {
      console.log(`raffle info is being sent to contract`);
      return niftyParams;
    },
    seeHash: (value) => {
      console.log(`winning number hash: ${value}`);
    },
    // implement Alice's interact object here
  }),
  backend.Bob(ctcBob, {
    ...stdlib.hasRandom,
    ...SharedFn,
    showNum: (num) => {
      console.log(`your raffle number : ${num}`);
    },
    seeWinner: (num) => {
      console.log(`Winning number : ${num}`);
    },
    // implement Bob's interact object here
  }),
]);

console.log('Goodbye, Alice and Bob!');

