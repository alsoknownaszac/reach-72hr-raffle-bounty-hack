'reach 0.1';

const amount = 1;

const SharedFn = {
  getNum: Fun([UInt], UInt),
  seeOutcome: Fun([UInt], Null),
}

const ManyUsers = API('users', {
  bids: Fun([UInt], UInt),
 
});

export const main = Reach.App(() => {
  const A = Participant('Alice', {
    // Specify Alice's interact interface
    ...SharedFn,
    ...hasRandom,
    startRaffle: Fun([], Object({
      nftId: Token,
      numOfTickets: UInt
    })),
    seeHash: Fun([Digest], Null),
  });
  const B = Participant('Bob', {
    // Specify Bob's interact interface here
    ...SharedFn,
    showNum: Fun([UInt], Null),
    seeWinner: Fun([UInt], Null),
  });
  init();
  A.only(()=> {
    const {nftId, numOfTickets}= declassify(interact.startRaffle());
    const _winningNumber = interact.getNum(numOfTickets);
    const [_commitA, _saltA] = makeCommitment(interact, _winningNumber);
    const commitA = declassify(_commitA);
  })
  // The first one to publish deploys the contract
  A.publish(nftId, numOfTickets, commitA);
  A.interact.seeHash(commitA)
  commit();
  A.pay([[amount, nftId]])
  commit()

  unknowable(B, A(_winningNumber, _saltA));

  B.only(() => {
    const myNum = declassify(interact.getNum(numOfTickets));
    interact.showNum(myNum);
  });

  // The second one to publish always attaches
  B.publish(myNum);
  commit();

  A.only(() => {
    const saltA = declassify(_saltA);
    const winningNumber = declassify(_winningNumber);
  });
  A.publish(saltA, winningNumber);
  checkCommitment(commitA, saltA, winningNumber);

  B.interact.seeWinner(winningNumber);

  const outcome = (myNum === winningNumber ? 1 : 0);

  transfer(amount, nftId).to(outcome === 1 ? B : A);

  each([A, B], () => {
    interact.seeOutcome(outcome);
  });

  // write your program here
  commit();
  exit();
});
