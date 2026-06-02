import { CONFIG } from "../config.js";
const stim_width_ex = "600px";
import { t } from "../state/participant.js";

const firstSetBlocks = Array.isArray(CONFIG.nbLearnBlocks)
  ? Number(CONFIG.nbLearnBlocks[0] ?? 0)
  : Number(CONFIG.nbLearnBlocks || 0);
const secondSetBlocks = Array.isArray(CONFIG.nbLearnBlocks)
  ? Number(CONFIG.nbLearnBlocks[1] ?? 0)
  : 0;
const firstSetBlockLabelEn = firstSetBlocks === 1 ? "block" : "blocks";
const secondSetBlockLabelEn = secondSetBlocks === 1 ? "block" : "blocks";
const firstSetBlockLabelIt = firstSetBlocks === 1 ? "blocco" : "blocchi";
const secondSetBlockLabelIt = secondSetBlocks === 1 ? "blocco" : "blocchi";

const INSTRUCTION_COPY = {
  it: {
    task1Part1: `
    <h1>Parte I</h1>
    <br>
    <h2>Compito 1</h2>
    <h3>Istruzioni</h3>
    <p>
      In questo compito vedrai diversi frutti e ortaggi disposti in un ambiente. Il tuo compito è <strong>trovare un elemento volante nascosto</strong> cliccando su di essi. Una volta trovato, osserva da dove parte e dove arriva, e cerca di ricordare questa connessione.
    </p>
    <p>
      Successivamente, ti chiediamo di <strong>disegnare il percorso dell'elemento volante</strong> cliccando su un frutto o ortaggio e trascinando il cursore fino a un altro. Questo crea una connessione tra i due elementi, e una linea verde o rossa indicherà se la connessione è corretta. Potrai passare alla prova successiva solo dopo aver disegnato la connessione corretta oppure dopo aver fatto più di 10 tentativi sbagliati. Tieni presente che la posizione di frutti e ortaggi può cambiare di tanto in tanto, ma questo non dovrebbe impedirti di disegnare la connessione giusta.
    </p>
    <p>
      Nota che la direzione in cui vedi muoversi l'elemento volante non è importante, perché ogni volta che si sposta da un elemento a un altro, vedrai anche lo stesso movimento nella direzione opposta. Allo stesso modo, non importa in quale direzione disegni la connessione.
    </p>
    <p>
      Di tanto in tanto, riceverai un punteggio di prestazione basato sulla frequenza con cui la tua prima risposta è stata corretta in una serie di prove.
    </p>
    <p>
      Prima di iniziare con il primo insieme di elementi, avrai la possibilità di completare <strong>due prove di esempio</strong> cliccando su "Continua". Successivamente, completerai ${firstSetBlocks} ${firstSetBlockLabelIt} con il primo insieme di elementi, seguiti da ${secondSetBlocks} ${secondSetBlockLabelIt} con il secondo insieme.
    </p>
  `,
    task1Part1End: `
    <h3>Sei pronto/a?</h3>
    <br>
    <p>
      La fase di pratica è ora terminata. Come spiegato in precedenza, il tuo compito è ricordare da dove è partito e dove è arrivato l'elemento volante in ogni prova.
    </p>
    <p>
      Se sei pronto/a, fai clic sul pulsante "Continua" per iniziare l'esperimento.
    </p>
  `,
    task1SetTransition: `
    <p>Hai completato il primo insieme di elementi.</p>
    <p>Se vuoi, puoi fare una breve pausa.</p>
    <p>Quando fai clic su "Continua", inizierà il secondo insieme di elementi.</p>
  `,
    task2Part1: `
    <h2>Compito 2</h2>
    <h3>Istruzioni</h3>
    <p>
      Hai notato che l'elemento volante si spostava solo tra alcune coppie di frutti e ortaggi, ma non tra altre?
    </p>
    <p>
      Chiamiamo il primo tipo <strong>connessioni note</strong> e il secondo tipo <strong>connessioni sconosciute</strong>. Potresti anche aver notato che, ogni volta che l'elemento volante conosceva una connessione, si muoveva con la stessa facilità in entrambe le direzioni, quindi la direzione non è importante.
    </p>
    <p>
      Nella parte seguente vedrai diverse coppie di frutti e ortaggi. Cerca di ricordare, dal compito precedente, <strong>se la connessione tra i due elementi mostrati era nota o sconosciuta per l'elemento volante</strong>.
    Indica la tua risposta cliccando uno dei pulsanti.
    </p>
    <p>
      Questa volta non c'è una prova di pratica, quindi puoi iniziare subito.
    </p>
  `,
    task1Part2: `
    <h1>Parte II</h1>
    <br>
    <h2>Compito 1</h2>
    <h3>Istruzioni</h3>
    <p>
      Nella parte di ieri dell'esperimento, hai imparato che l'elemento volante si sposta solo tra alcune coppie di frutti e ortaggi. Queste sono le <strong>connessioni note</strong>.
    </p>
    <p>
      Oggi, l'elemento volante deve spostarsi tra frutti e ortaggi che <strong>non sono direttamente collegati</strong>. Per raggiungerli, deve viaggiare <strong>indirettamente</strong>, passando attraverso altri elementi e usando le <strong>connessioni note di ieri</strong>.
    </p>
    <p>
      Ogni volta che l'elemento volante si ferma su un elemento intermedio, questo conta come una sosta e richiede tempo. Il tuo compito è quindi aiutarlo a trovare il percorso con il <strong>minor numero di soste</strong>.
    </p>
    <p>
      Nella parte seguente, svolgerai questo compito per l'elemento volante.
    </p>
    <br>
  `,
    taskPart2Intro: `
    <h1>Parte II</h1>
    <br>
    <h2>Istruzioni</h2>
    <p>
      In questa parte continuerai a usare le connessioni note apprese in precedenza.
    </p>
    <p>
      In ogni prova, vedrai prima un singolo frutto o ortaggio. Successivamente, vedrai due frutti o ortaggi e dovrai decidere quale dei due può essere raggiunto dal primo con il minor numero di soste, passando attraverso le connessioni note.
    </p>
    <p>
      Ti preghiamo di basare la tua risposta sulle connessioni apprese in precedenza e di contare attentamente il numero di soste.
    </p>
    <p>
      Usa i tasti freccia sinistra e freccia destra per rispondere.
    </p>
  `,
    task2Part2First: `
    <h2>Compito 2</h2>
    <h3>Istruzioni</h3>
    <br>
    <p>
      Nella prossima parte dell'esperimento, ti chiediamo di <strong>disporre i frutti e gli ortaggi nell'ambiente</strong> in un modo che ti sembri ragionevole.
    </p>
    <p>
      All'inizio, i frutti e gli ortaggi appariranno sul lato destro. Per collocarne uno nell'ambiente, cliccaci sopra e trascinalo nella posizione che ti sembra più adatta. Puoi modificare la disposizione tutte le volte che vuoi trascinando di nuovo gli elementi.
    </p>
    <p>
      Per questa parte non è prevista una prova di pratica. Prenditi tutto il tempo di cui hai bisogno.
    </p>
    <br>
  `,
    task2Part2Sec: `
    <h3>Istruzioni</h3>
    <p>
      Successivamente, ti mostreremo l'ambiente con i frutti e gli ortaggi disposti come li hai collocati in precedenza. Questa volta, ti chiediamo di <strong>disegnare le connessioni note</strong> così come le ricordi.
    </p>
    <p>
      Come nel compito precedente, puoi disegnare le connessioni <strong>trascinando il cursore</strong> da un frutto o ortaggio a un altro. Se vuoi rimuovere una connessione che hai già disegnato, puoi <strong>fare doppio clic</strong> su di essa oppure usare il <strong>pulsante di reset</strong>, che elimina tutte le connessioni disegnate in una sola volta.
    </p>
    <p>
      Assicurati che l'elemento volante possa raggiungere ogni frutto e ortaggio attraverso almeno una connessione.
    </p>
    <p>
      Non c'è alcun limite di tempo. Prenditi tutto il tempo di cui hai bisogno e fai clic su "Continua" quando hai finito.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulazioni, hai quasi finito. Un'ultima domanda:</h3>
    <br>
    <p>
      Hai utilizzato qualche forma di aiuto esterno per imparare le connessioni dell'elemento volante nella Parte I o per risolvere il compito nella Parte II (per esempio scrivendo le connessioni)?
    </p>
    <p>
      (Per favore, rispondi onestamente. La tua risposta a questa domanda non influenzerà in alcun modo il tuo compenso.)
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
    In this task, you will see several fruits and vegetables arranged in an environment. Your task is to <strong>find a hidden flying figure</strong> by clicking on them. Once you find it, observe where it moves from and where it moves to, and remember this connection.
    </p>
    <p>
    Next, we ask you to <strong>draw the path of the flying figure</strong> by clicking on one fruit or vegetable and dragging the cursor to another. This creates a connection between the two, and a green or red line indicates whether the connection is correct. You can continue to the next trial only after drawing the correct connection or after making more than 10 incorrect attempts. Please note that the positions of the fruits and vegetables may change from time to time, but this should not affect your ability to draw the correct connection.
    </p>
    <p>
    Note that the direction in which you see the flying figure move is not important, because whenever it moves from
    one item to another, you will also see the same movement in the opposite direction. Likewise, it does not matter
    in which direction you draw the connection.
    </p>
    <p>
    From time to time, you will receive a performance score based on your first-attempt accuracy across several trials.
    </p>
    <p>
    Over the course of the experiment, you will work with two different sets of items, and each set will be associated
    with a different flying figure.
    </p>
    <p>
    Before starting with the first set of items, you will have the chance to complete <strong>two example trials</strong> by
    clicking "Continue." Afterward, you will complete ${firstSetBlocks} ${firstSetBlockLabelEn} with the first set of items,
    followed by ${secondSetBlocks} ${secondSetBlockLabelEn} with the second set.
    </p>
  `,
    task1Part1End: `
    <h3>Are you ready?</h3>
    <br>
    <p>
    The practice phase is now over. As explained earlier, your task is to remember where the flying figure started and
    where it ended in each trial.
    </p>
    <p>
    If you are ready, click the 'Continue' button to begin the experiment with the <strong>first set</strong> of items.
    </p>
  `,
    task1SetTransition: `
    <p>You have finished the first set of items. At this point, please take a short break if you like.</p>
    <p>When you click 'Continue,' the <strong>second set</strong> of items will begin.</p>
   `,
    task2Part1: `
    <h2>Task 2</h2>
    <h3>Instructions</h3>
    <p>
    Did you notice that the flying figure moved only between certain pairs of fruits and vegetables, but not between others?
    </p>
    <p>
    We call the first type <strong>known connections</strong> and the second type <strong>unknown connections</strong>. You may also have noticed that whenever the flying figure knew a connection, it moved equally well in both directions, so direction is not important.
    </p>
    <p>
    In the following, you will see several pairs of fruits and vegetables. Please try to remember from the previous task <strong>whether the connection between the two shown items was known or unknown to the flying figure</strong>.
    Indicate your answer by clicking one of the buttons.
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
      In yesterday's part of the experiment, you learned that the flying figure moves only between certain pairs of fruits and vegetables. These are the <strong>known connections</strong>.
      </p>
      <p>
      Today, the flying figure needs to move between fruits and vegetables that are <strong>not directly
      connected</strong>. To reach them, it must travel <strong>indirectly</strong> by
      passing through other fruits and vegetables using the <strong>known connections from yesterday</strong>.
      </p>
      <p>
      Each time the flying figure stops at an intermediate item, this counts as a stopover and takes time.
      Your task is therefore to help it find the route with the <strong>fewest stopovers</strong>.
      </p>
      <p>
      In the following, you will carry out this task for the flying figure.
      </p>
      <br>
    `,
    taskPart2Intro: `
      <h1>Part II</h1>
      <br>
      <h2>Instructions</h2>
      <p>
        In this part, you will continue to use the known connections you learned earlier.
      </p>
      <p>
        On each trial, you will first see a single fruit or vegetable. After that, you will see two fruits or vegetables and decide which of the two can be reached from the first with fewer stopovers by moving through the known connections.
      </p>
      <p>
        Please base your answer on the connections you learned earlier and count the number of stopovers carefully.
      </p>
      <p>
        Use the left and right arrow keys to respond.
      </p>
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
    As in the earlier task, you can draw connections by <strong>dragging the cursor</strong> from one fruit or vegetable
    to another. If you want to remove a connection you have already drawn, you can <strong>double-click</strong> on it
    or use the <strong>reset button</strong>, which deletes all previously drawn connections at once.
    </p>
    <p>
    Please make sure that the flying figure can reach every fruit and vegetable through at least one connection.
    </p>
    <p>
    There is no time limit. Take as much time as you need, and click "Continue" once you are done.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulations, you are nearly done. One last question:</h3>
    <br>
    <p>
    Did you use any form of external aid to learn the flying figure's connections in Part I, or to
    solve the task in Part II (for example, by writing the connections down)?
    </p>
    <p>
    (Please answer honestly. Your response to this question will not affect your payment in any way.)
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
