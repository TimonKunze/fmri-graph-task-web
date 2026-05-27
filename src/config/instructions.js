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
      In this task, you will see several flowers on a meadow. Your task is to <strong>find a hidden bee</strong> by clicking on the flowers. When you have found the bee, observe from which flower the bee flies to which other flower and remember this.
    </p>
    <p>
      Next, we ask you to <strong>draw the bee's flight path</strong> by clicking on one flower and dragging the cursor to another flower. This creates a connection between the two flowers, and a green or red line indicates whether the connection is correct. Only if your drawing was correct, or if you have drawn more than 10 incorrect connections, can you move on to the next trial. Please be aware that during this task the position of the flowers on the meadow may change from time to time, but this should not hinder you in drawing the correct connection.
    </p>
    <p>
      Note that, firstly, the direction in which you see the bee flying does not matter, because for every direction in which you see a bee flying, we will also present you with the opposite direction. Similarly, it doesn't matter in which direction you draw the connection.
    </p>
    <p>
      Periodically give you a performance score based on your first-attempt accuracy over multiple trials.
    </p>
    <p>
      Before starting, you can try <strong>two example trials</strong> by clicking 'Continue.'
    </p>
  `,
    task1Part1End: `
    <h3>Are you ready?</h3>
    <br>
    <p>
      The testing phase is over. As said before, the task is to remember start and end position of the bee in each trial.
    </p>
    <p>
      If you are ready you can click on the 'Continue' button, and the experiment begins.
    </p>
  `,
    task2Part1: `
    <h2>Task 2</h2>
    <h3>Instructions</h3>
    <p>
      Did you notice that the bee only flew between certain pairs of flowers and not between others? We call the former <strong>&ldquo;known pairs&rdquo;</strong> and the latter <strong>&ldquo;unknown pairs&rdquo;</strong>. You may also have noticed that if the bee knew a connection, it flew equally in both directions, as such the directionality is not important..
    </p>
    <p>
      In the following, we show you several pairs of flowers, and please try to remember from the previous task <strong>whether the bee knows or does not know the shown flower pair</strong>.
    </p>
    <p>
      Indicate your answer with a button click. The task looks like this:
    </p>
    <p>
      <img src="/stimuli/other/reltest_example.png" style="max-width:${stim_width_ex};max-height:${stim_width_ex};">
    </p>
    <p>
      This time, you don't need a test trial. Go right ahead.
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
      In the next part of the experiment we ask you to <strong>position the flowers on the meadow</strong> in a way that seems reasonable to you.
    </p>
    <p>
      To begin with, the flowers are placed on the right-hand side. To place a flower on the meadow, click on the flower and drag it to a place you think fits best. Note that you can adjust the positions by dragging and droping flowers multiple times.
    </p>
    <p>
      There is no test attempt since you will figure it out easily. Take as much time as you like.
    </p>
    <br>
  `,
    task2Part2Sec: `
    <h3>Instructions</h3>
    <p>
      Next, we show you the meadow with the flowers as you positioned them before. But this time we ask you to <strong>draw in the known connections</strong> as you remember them.
    </p>
    <p>
      You can draw connections as before by <strong>dragging and dropping</strong> the cursor from one flower to another. If you want to delete an already drawn connection you can <strong>double-click</strong> on it, or you click on the <strong>reset button</strong> that deletes all previosly drawn connection in one go.
    </p>
    <p>
      Please make sure that the bee can reach all flowers by at least one connection.
    </p>
    <p>
      There's no time limit. Take your time and click on 'Continue' once you are done.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulations, you are nearly done. One last question:</h3>
    <br>
    <p>
      Did you use any means of documentation for learning the bee's connections in part 1, or for solving the task in part 2 (e.g. by writing down the connections)?
    </p>
    <p>
      (Please be honest and note that your answer to this question will not affect your payment in any way.)
    </p>
  `,
  },
};

export function getInstructions() {
  return t(INSTRUCTION_COPY);
}
