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
      In questo compito vedrai diversi alimenti disposti in un ambiente. Il tuo compito è <strong>trovare un pipistrello nascosto</strong> cliccando su di essi. Una volta trovato, osserva da dove parte e dove arriva, e cerca di ricordare questa connessione.
    </p>
    <p>
      Successivamente, ti chiediamo di <strong>disegnare il percorso del pipistrello</strong> cliccando su un alimento e trascinando il cursore fino a un altro. Questo crea una connessione tra i due elementi, e una linea verde o rossa indicherà se la connessione è corretta. Potrai passare alla prova successiva solo dopo aver disegnato la connessione corretta oppure dopo aver fatto più di 10 tentativi sbagliati. Tieni presente che la posizione degli alimenti può cambiare di tanto in tanto, ma questo non dovrebbe impedirti di disegnare la connessione giusta.
    </p>
    <p>
      Nota che la direzione in cui vedi muoversi il pipistrello non è importante, perché ogni volta che si sposta da un elemento a un altro, vedrai anche lo stesso movimento nella direzione opposta. Allo stesso modo, non importa in quale direzione disegni la connessione.
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
      La fase di pratica è ora terminata. Come spiegato in precedenza, il tuo compito è ricordare da dove è partito e dove è arrivato il pipistrello in ogni prova.
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
      Hai notato che il pipistrello si spostava solo tra alcune coppie di alimenti?
    </p>
    <p>
      Chiamiamo queste coppie <strong>connessioni</strong>. Potresti anche aver notato che, ogni volta che il pipistrello seguiva una connessione, si muoveva con la stessa facilità in entrambe le direzioni. Questo significa che la direzione non è importante.
    </p>
    <p>
      Nella parte seguente vedrai diverse coppie di alimenti. Cerca di ricordare dal compito precedente
      <strong>se tra i due elementi mostrati c'era una connessione oppure no</strong>. Indica la tua risposta
      cliccando uno dei pulsanti.
    </p>
    <p>
      Questa volta non c'è una prova di pratica, quindi puoi iniziare subito.
    </p>
  `,
    part2Intro: `
    <h1>Parte II</h1>
    <br>
    <h3>Istruzioni</h3>
    <p>
      Nella parte di ieri dell'esperimento, hai imparato che il pipistrello si sposta solo tra alcune coppie di alimenti. Queste sono le <strong>connessioni</strong>.
    </p>
    <p>
      Oggi, vedrai prima immagini singole di alimenti, presentate una dopo l'altra. Ti preghiamo di osservare attentamente ciascuna immagine.
    </p>
    <p>
      A volte, dopo un'immagine singola, appariranno due immagini. In questi casi, cerca di ricordare l'immagine singola mostrata immediatamente prima. A differenza di ieri, le due immagini non formeranno una connessione diretta. Il tuo compito sarà decidere quale delle due immagini può essere raggiunta a partire dall'immagine precedente usando un numero minore di connessioni, assumendo il ruolo del pipistrello.
    </p>
    <p>
      Usa i tasti freccia sinistra e freccia destra per rispondere.
    </p>
    <p>
      Per continuare, premi il tasto freccia destra e ti mostreremo una breve dimostrazione.
    </p>
  `,
    part2Demo: `
    <h3>Dimostrazione</h3>
    <p>
      Questa è solo una <strong>dimostrazione</strong> e <strong>non</strong> fa parte del compito reale.
    </p>
    <p>
      In alto vedrai tre brevi video di esempio. Al centro dello schermo vedrai prima immagini singole e poi una prova di scelta del percorso.
    </p>
    <p>
      Dopo la dimostrazione, potrai ripeterla tutte le volte che vuoi oppure continuare con il compito reale.
    </p>
  `,
    part2Start: `
    <h3>Inizio dell'esperimento</h3>
    <p>
      Benissimo. Ora hai imparato come funziona il compito.
    </p>
    <p>
      Quando premi il tasto freccia destra, inizierà l'esperimento vero e proprio.
    </p>
    <p>
      È prevista una pausa circa ogni 8 minuti, durante la quale potrai riposarti un momento. L'esperimento durerà circa un'ora in totale.
    </p>
  `,
    part3First: `
    <h2>Parte III</h2>
    <h3>Istruzioni</h3>
    <br>
    <p>
      Nella prossima parte dell'esperimento, ti chiediamo di <strong>disporre gli alimenti nell'ambiente</strong> in un modo che ti sembri ragionevole.
    </p>
    <p>
      All'inizio, gli alimenti appariranno sul lato destro. Per collocarne uno nell'ambiente, cliccaci sopra e trascinalo nella posizione che ti sembra più adatta. Puoi modificare la disposizione tutte le volte che vuoi trascinando di nuovo gli elementi.
    </p>
    <p>
      Per questa parte non è prevista una prova di pratica. Prenditi tutto il tempo di cui hai bisogno.
    </p>
    <p>
      Dopo aver premuto "Continua", la prova successiva inizierà con il primo insieme di elementi.
    </p>
    <br>
  `,
    part3Second: `
    <h3>Istruzioni</h3>
    <p>
      Successivamente, ti mostreremo l'ambiente con gli alimenti disposti come li hai collocati in precedenza. Questa volta, ti chiediamo di <strong>disegnare le connessioni</strong> così come le ricordi.
    </p>
    <p>Come nel compito di ieri, puoi disegnare le connessioni <strong>trascinando il cursore</strong> da un alimento
    a un altro. Se vuoi rimuovere una connessione che hai già disegnato, puoi <strong>fare
    doppio clic</strong> su di essa oppure usare il <strong>pulsante di reset</strong>, che elimina
    tutte le connessioni disegnate in una sola volta.
    </p>
    <p>
      Assicurati che il pipistrello possa raggiungere ogni alimento attraverso almeno una connessione.
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
    Hai utilizzato qualche forma di aiuto esterno per imparare le connessioni del pipistrello nella Parte I
    o per risolvere il compito nelle Parti II o III (per esempio scrivendo le connessioni)?
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
    In this task, you will see several food items arranged in an environment. Your task is
    to <strong>find a hidden bat</strong> by clicking on them. Once you find it, observe
    where it moves from and where it moves to, and remember this connection.
    </p>
    <p>
    Next, we ask you to <strong>draw the path of the bat</strong> by clicking on one food item
    and dragging the cursor to another. This creates a connection between the two, and
    a green or red line indicates whether the connection is correct. You can continue to the next trial
    only after drawing the correct connection or after making more than 10 incorrect attempts. Please
    note that the positions of the food items may change from time to time, but this should
    not affect your ability to draw the correct connection.
    </p>
    <p>
    Note that the direction in which you see the bat move is not important, because whenever it moves from
    one item to another, you will also see the same movement in the opposite direction. Likewise, it does not matter
    in which direction you draw the connection.
    </p>
    <p>
    From time to time, you will receive a performance score based on your first-attempt accuracy across several trials.
    </p>
    <p>
    Over the course of the experiment, you will work with two different sets of items, and each set will be associated
    with a different bat.
    </p>
    <p>
    Before starting with the first set of items, you will have the chance to complete <strong>two practice
    trials</strong> by
    clicking "Continue." Afterward, you will complete ${firstSetBlocks} ${firstSetBlockLabelEn} with the first set of items,
    followed by ${secondSetBlocks} ${secondSetBlockLabelEn} with the second set.
    </p>
  `,
    task1Part1End: `
    <h3>Are you ready?</h3>
    <br>
    <p>
    The practice phase is now over. As explained earlier, your task is to remember where the bat started and
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
    Did you notice that the bat moved only between certain pairs of food items?
    </p>
    <p>
    We call these pairs <strong>connections</strong>. You may also have noticed that whenever the bat followed a connection,
    it moved equally well in both directions. This means that direction does not matter.
    </p>
    <p>
    In the following, you will see several pairs of food items. Please try to remember from the previous task
    <strong>whether there was a connection between the two shown items or not</strong>. Indicate your answer
    by clicking one of the buttons.
    </p>
    <p>
    This time, there is no practice trial, so you can begin right away.
    </p>
  `,
    part2Intro: `
    <h1>Part II</h1>
    <br>
    <h3>Instructions</h3>
    <p>
    In yesterday's part of the experiment, you learned that the bat moved only between certain pairs of food items. These are the <strong>connections</strong>.
    </p>
    <p>
    Today, you will first see single images of food items, presented one after another.
    Please pay close attention to each image.
    </p>
    <p>
    Occasionally, <strong>two images</strong> will appear after a single image. In those cases,
    please remember the single image shown immediately before. Unlike yesterday, the two images
    will not form a direct connection. 
    </p>
    <p>
    Your task is to decide which of the two items can be reached from the previous item using
    <strong>fewer connections</strong>, while taking the role of the bat.
    </p>
    <p>
    Use the left and right arrow keys to respond.
    </p>
    <p>
    Press the right arrow key now, and we will show you a short demo.
    </p>
    `,
    part2Demo: `
    <p>
    Imagine that, yesterday, you learned these three connections.
    </p>
    `,
    part2Start: `
    <h3>Start of the Experiment</h3>
    <p>
    Good. You have now learned the task.
    </p>
    <p>
    When you press the right arrow key, the actual experiment will begin.
    </p>
    <p>
    There will be a scheduled break about every 8 minutes, so you will have regular opportunities to rest briefly. The experiment will take about one hour in total.
    </p>
    `,
    part3First: `
    <h2>Part III</h2>
    <h3>Instructions</h3>
    <br>
    <p>
    In the next part of the experiment, we ask you to <strong>arrange the food items in the environment</strong> in a way that seems reasonable to you.
    </p>
    <p>
    At the beginning, food items will appear on the right-hand side. To place one in the
    environment, click on it and drag it to the position you think fits best. You can adjust the arrangement
    as often as you like by dragging the items again.
    </p>
    <p>
    There is no practice trial for this part. Take as much time as you need.
    </p>
    <p>
    After pressing "Continue," the next trial will begin with the first set of items.
    </p>
    <br>
  `,
    part3Second: `
    <h3>Instructions</h3>
    <p>
    Next, we will show you the environment with the food items arranged as you placed them before.
    This time, we ask you to <strong>draw the connections</strong> as you remember them.
    </p>
    <p>
    As in yesterday's task, you can draw connections by <strong>dragging the cursor</strong> from one food item
    to another. If you want to remove a connection you have already drawn, you can <strong>double-click</strong> on it
    or use the <strong>reset button</strong>, which deletes all previously drawn connections at once.
    </p>
    <p>
    Please make sure that the bat can reach every food item through at least one connection.
    </p>
    <p>
    There is no time limit. Take as much time as you need, and click "Continue" once you are done.
    </p>
    <br>
  `,
    cheater: `
    <h3>Congratulations, you are nearly done. One very last question:</h3>
    <br>
    <p>
    Did you use any form of external aid to learn the bat's connections in Part I, or to
    solve the tasks in Part II and III (for example, by writing the connections down)?
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
