const stim_width_ex = "600px";
import { t } from "../state/participant.js";

const INSTRUCTION_COPY = {
  it: {
    task1Part1: `
    <h1>Parte I</h1>
    <br>
    <h2>Compito 1</h2>
    <h3>Istruzioni</h3>
    <p>
      In questo compito vedrai diversi fiori in un prato. Il tuo compito e <strong>trovare un'ape nascosta</strong> cliccando sui fiori. Quando hai trovato l'ape, osserva da quale fiore vola verso quale altro fiore e ricordalo.
    </p>
    <p>
      Poi ti chiederemo di <strong>disegnare il percorso di volo dell'ape</strong> cliccando su un fiore e trascinando il cursore verso un altro fiore. Questo crea una connessione tra i due fiori e una linea verde o rossa indica se la connessione e corretta. Potrai passare alla prova successiva solo se il tuo disegno e corretto oppure se hai disegnato piu di 10 connessioni sbagliate. Tieni presente che durante questo compito la posizione dei fiori nel prato puo cambiare di tanto in tanto, ma questo non dovrebbe impedirti di disegnare la connessione corretta.
    </p>
    <p>
      Nota che la direzione in cui vedi volare l'ape non e importante, perche per ogni direzione in cui vedi volare un'ape presenteremo anche la direzione opposta. Allo stesso modo, non importa in quale direzione disegni la connessione.
    </p>
    <p>
      Periodicamente ti verra mostrato un punteggio di prestazione basato sull'accuratezza del primo tentativo in piu prove.
    </p>
    <p>
      Prima di iniziare puoi provare <strong>due prove di esempio</strong> cliccando su "Continua".
    </p>
  `,
    task1Part1End: `
    <h3>Sei pronto/a?</h3>
    <br>
    <p>
      La fase di prova e terminata. Come detto prima, il compito consiste nel ricordare la posizione iniziale e finale dell'ape in ogni prova.
    </p>
    <p>
      Se sei pronto/a puoi fare clic sul pulsante "Continua" e l'esperimento iniziera.
    </p>
  `,
    task2Part1: `
    <h2>Compito 2</h2>
    <h3>Istruzioni</h3>
    <p>
      Hai notato che l'ape volava solo tra alcune coppie di fiori e non tra altre? Chiamiamo le prime <strong>&ldquo;coppie note&rdquo;</strong> e le seconde <strong>&ldquo;coppie sconosciute&rdquo;</strong>. Potresti anche aver notato che se l'ape conosceva una connessione, volava in entrambe le direzioni con la stessa facilita, quindi la direzione non e importante.
    </p>
    <p>
      Di seguito ti mostreremo diverse coppie di fiori e ti chiediamo di ricordare dal compito precedente <strong>se l'ape conosceva o non conosceva la coppia mostrata</strong>.
    </p>
    <p>
      Indica la tua risposta con un clic sul pulsante. Il compito si presenta cosi:
    </p>
    <p>
      <img src="/stimuli/other/reltest_example.png" style="max-width:${stim_width_ex};max-height:${stim_width_ex};">
    </p>
    <p>
      Questa volta non hai bisogno di una prova di allenamento. Puoi iniziare subito.
    </p>
  `,
    task1Part2: `
    <h1>Parte II</h1>
    <br>
    <h2>Compito 1</h2>
    <h3>Istruzioni</h3>
    <p>
      Nella parte di ieri dell'esperimento hai imparato che l'ape vola solo tra alcune coppie note di fiori e non vola tra altre coppie sconosciute.
    </p>
    <p>
      Oggi ti chiediamo di aiutare l'ape a volare tra fiori le cui connessioni non sono note. Per farlo, l'ape dovra andare da un fiore all'altro <strong>indirettamente</strong> tramite le <strong>connessioni note di ieri</strong>.
    </p>
    <p>
      Nota pero che l'ape deve fare una sosta quando passa da un fiore all'altro tramite connessioni note, e ogni sosta richiede tempo. E quindi importante che l'ape trovi il percorso con <strong>meno soste</strong>.
    </p>
    <p>
      Nella parte seguente ti chiediamo di svolgere questo compito per l'ape...
    </p>
    <br>
  `,
    task2Part2First: `
    <h2>Compito 2</h2>
    <h3>Istruzioni</h3>
    <br>
    <p>
      Nella prossima parte dell'esperimento ti chiediamo di <strong>posizionare i fiori nel prato</strong> in un modo che ti sembri ragionevole.
    </p>
    <p>
      All'inizio i fiori sono posizionati sul lato destro. Per collocare un fiore nel prato, clicca sul fiore e trascinalo nel punto che ritieni piu adatto. Nota che puoi modificare le posizioni trascinando i fiori piu volte.
    </p>
    <p>
      Non c'e una prova di test perche il compito e intuitivo. Prenditi tutto il tempo che vuoi.
    </p>
    <br>
  `,
    task2Part2Sec: `
    <h3>Istruzioni</h3>
    <p>
      Ora ti mostreremo il prato con i fiori nelle posizioni che hai scelto prima. Questa volta ti chiediamo di <strong>disegnare le connessioni note</strong> cosi come le ricordi.
    </p>
    <p>
      Puoi disegnare le connessioni come prima <strong>trascinando</strong> il cursore da un fiore all'altro. Se vuoi eliminare una connessione gia disegnata puoi fare <strong>doppio clic</strong> su di essa, oppure cliccare sul <strong>pulsante di reset</strong> che elimina tutte le connessioni gia disegnate in un colpo solo.
    </p>
    <p>
      Assicurati che l'ape possa raggiungere tutti i fiori con almeno una connessione.
    </p>
    <p>
      Non c'e limite di tempo. Prenditi il tempo necessario e fai clic su "Continua" quando hai finito.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulazioni, hai quasi finito. Un'ultima domanda:</h3>
    <br>
    <p>
      Hai usato qualche forma di documentazione per imparare le connessioni dell'ape nella parte 1, o per risolvere il compito nella parte 2 (per esempio scrivendo le connessioni)?
    </p>
    <p>
      (Per favore rispondi onestamente e nota che la tua risposta a questa domanda non influenzera in alcun modo il tuo compenso.)
    </p>
  `,
  },
  en: {
    task1Part1: `
    <h1>Part I</h1>
    <br>
    <h2>Task 1</h2>
    <h3>Instructions</h3>
    <p>
      In this task, you will see several fruits and vegetables arranged in an environment. Your task is to <strong>find a hidden flying creature</strong> by clicking on them. Once you find it, observe where it moves from and where it moves to, and remember this connection.
    </p>
    <p>
      Next, we ask you to <strong>draw the path of the flying creature</strong> by clicking on one fruit or vegetable and dragging the cursor to another. This creates a connection between the two, and a green or red line indicates whether the connection is correct. You can continue to the next trial only after drawing the correct connection or after making more than 10 incorrect attempts. Please note that the positions of the fruits and vegetables may change from time to time, but this should not affect your ability to draw the correct connection.
    </p>
    <p>
      Note that the direction in which you see the flying creature move is not important, because whenever it moves from one item to another, you will also see the same movement in the opposite direction. Likewise, it does not matter in which direction you draw the connection.
    </p>
    <p>
      From time to time, you will receive a performance score based on your first-attempt accuracy across several trials.
    </p>
    <p>
      Before starting, you will have the chance to complete <strong>two example trials</strong> by clicking 'Continue.'
    </p>
  `,
    task1Part1End: `
    <h3>Are you ready?</h3>
    <br>
    <p>
    The practice phase is now over. As explained earlier, your task is to remember where the flying creature started and
    where it ended in each trial.
    </p>
    <p>
      If you are ready, click the “Continue” button to begin the experiment.
    </p>
  `,
    task2Part1: `
    <h2>Task 2</h2>
    <h3>Instructions</h3>
    <p>
    Did you notice that the flying creature moved only between certain pairs of fruits and vegetables, but not between others?
    We call the former <strong>&ldquo;known pairs&rdquo;</strong> and the latter <strong>&ldquo;unknown pairs&rdquo;</strong>.
    You may also have noticed that whenever the flying creature knew a connection, it moved equally in both directions, so the
    direction is not important.
    </p>
    <p>
    In the following, you will see several pairs of fruits and vegetables. Please try to remember from the previous task
    <strong>whether the flying creature knew or did not know the connection between the two shown items</strong>.
    </p>
    <p>
    Please indicate your answer by clicking one of the buttons. The task looks like this:
    </p>
    <p>
      <img src="/stimuli/other/reltest_example.png" style="max-width:${stim_width_ex};max-height:${stim_width_ex};">
    </p>
    <p>
    This time, there is no practice trial, so you can begin right away.
    </p>
  `,
    task1Part2: `
    <h1>Part II</h1>
    <br>
    <h2>Task 1</h2>
    <h3>Instructions</h3>
    <p>
      In yesterday's part of the experiment, you have learned that the bee only flies between certain known pairs of flowers and does not fly between other, unknown pairs of flowers.
    </p>
    <p>
      Today we ask you to help the bee fly between flowers whose connections are not known. In order to do so, the bee will need to go from one flower to the next <strong>indirectly</strong> via the <strong>known connections from yesterday</strong>.
    </p>
    <p>
      Note, however, that the bee must make a stopover when passing flowers via known connections, and each of these stopovers takes time. It is therefore important that the bee finds out which route has the <strong>fewest stopovers</strong>.
    </p>
    <p>
      In the following, we like to ask you to take over this task for the bee...
    </p>
    <br>
  `,
    task2Part2First: `
    <h2>Task 2</h2>
    <h3>Instructions</h3>
    <br>
    <p>
    In the next part of the experiment, we ask you to <strong>arrange the fruits and vegetables in the
    environment</strong> in a way that seems reasonable to you.
    </p>
    <p>
    At the beginning, the fruits and vegetables will appear on the right-hand side. To place one in the
    environment, click on it and drag it to the position you think fits best. You can adjust the arrangement
    as often as you like by dragging the items again.
    </p>
    <p>
    There is no practice trial for this part. Take as much time as you need.
    </p>
    <br>
  `,
    task2Part2Sec: `
    <h3>Instructions</h3>
    <p>
    Next, we will show you the environment with the fruits and vegetables arranged as you placed them before.
    This time, we ask you to <strong>draw the known connections</strong> as you remember them.
    </p>
    <p>
    As in yesterday's task, you can draw connections by <strong>dragging the cursor</strong> from one fruit or vegetable
    to another. If you want to remove a connection you have already drawn, you can <strong>double-click</strong> on it
    or use the <strong>reset button</strong>, which deletes all previously drawn connections at once.
    </p>
    <p>
    Please make sure that the flying creature can reach every fruit and vegetable through at least one connection.
    </p>
    <p>
    Again, there is no time limit. Take as much time as you need, and click 'Continue' once you are done.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulations, you are nearly done. One last question:</h3>
    <br>
    <p>
    Did you use any form of external aid to learn the flying creature’s connections in Part 1, or to
    solve the task in Part 2 (for example, by writing the connections down or taking screenshots)?
    </p>
    <p>
    (Please answer honestly. Your response to this question will not affect your compensation in any way.)
    </p>
  `,
  },
};

export function getInstructions() {
  const copy = t(INSTRUCTION_COPY);

  return Object.fromEntries(
    Object.entries(copy).map(([key, value]) => [
      key,
      typeof value === "string" && !value.includes('class="instr-screen"')
        ? `<div class="instr-screen">${value}</div>`
        : value,
    ])
  );
}
