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
      In questo compito vedrai diversi frutti e ortaggi disposti in un ambiente. Il tuo compito è <strong>trovare una creatura volante nascosta</strong> cliccando su di essi. Una volta trovata, osserva da dove parte e dove arriva, e cerca di ricordare questa connessione.
    </p>
    <p>
      Successivamente, ti chiediamo di <strong>disegnare il percorso della creatura volante</strong> cliccando su un frutto o ortaggio e trascinando il cursore fino a un altro. Questo crea una connessione tra i due elementi, e una linea verde o rossa indicherà se la connessione è corretta. Potrai passare alla prova successiva solo dopo aver disegnato la connessione corretta oppure dopo aver fatto più di 10 tentativi sbagliati. Tieni presente che la posizione di frutti e ortaggi può cambiare di tanto in tanto, ma questo non dovrebbe impedirti di disegnare la connessione giusta.
    </p>
    <p>
      Nota che la direzione in cui vedi muoversi la creatura volante non è importante, perché ogni volta che si sposta da un elemento a un altro, vedrai anche lo stesso movimento nella direzione opposta. Allo stesso modo, non importa in quale direzione disegni la connessione.
    </p>
    <p>
      Di tanto in tanto, riceverai un punteggio di prestazione basato sulla frequenza con cui la tua prima risposta è stata corretta in una serie di prove.
    </p>
    <p>
      Prima di iniziare, avrai la possibilità di completare <strong>due prove di esempio</strong> cliccando su "Continua".
    </p>
  `,
    task1Part1End: `
    <h3>Sei pronto/a?</h3>
    <br>
    <p>
      La fase di pratica è ora terminata. Come spiegato in precedenza, il tuo compito è ricordare da dove è partita e dove è arrivata la creatura volante in ogni prova.
    </p>
    <p>
      Se sei pronto/a, fai clic sul pulsante "Continua" per iniziare l'esperimento.
    </p>
  `,
    task2Part1: `
    <h2>Compito 2</h2>
    <h3>Istruzioni</h3>
    <p>
      Hai notato che la creatura volante si spostava solo tra alcune coppie di frutti e ortaggi, ma non tra altre? Chiamiamo le prime <strong>&ldquo;coppie note&rdquo;</strong> e le seconde <strong>&ldquo;coppie sconosciute&rdquo;</strong>. Potresti anche aver notato che, ogni volta che la creatura volante conosceva una connessione, si muoveva con la stessa facilità in entrambe le direzioni, quindi la direzione non è importante.
    </p>
    <p>
      Nella parte seguente vedrai diverse coppie di frutti e ortaggi. Cerca di ricordare, dal compito precedente, <strong>se la creatura volante conosceva o non conosceva la connessione tra i due elementi mostrati</strong>.
    </p>
    <p>
      Indica la tua risposta cliccando uno dei pulsanti. Il compito si presenta così:
    </p>
    <p>
      <img src="/stimuli/other/reltest_example.png" style="max-width:${stim_width_ex};max-height:${stim_width_ex};">
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
      Nella parte di ieri dell'esperimento, hai imparato che la creatura volante si sposta solo tra alcune coppie di frutti e ortaggi. Queste sono le <strong>connessioni note</strong>.
    </p>
    <p>
      Oggi, la creatura volante deve spostarsi tra frutti e ortaggi che <strong>non sono direttamente collegati</strong>. Per raggiungerli, deve viaggiare <strong>indirettamente</strong>, passando attraverso altri elementi e usando le <strong>connessioni note di ieri</strong>.
    </p>
    <p>
      Ogni volta che la creatura volante si ferma su un elemento intermedio, questo conta come una sosta e richiede tempo. Il tuo compito è quindi aiutarla a trovare il percorso con il <strong>minor numero di soste</strong>.
    </p>
    <p>
      Nella parte seguente, svolgerai questo compito per la creatura volante.
    </p>
    <br>
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
      Assicurati che la creatura volante possa raggiungere ogni frutto e ortaggio attraverso almeno una connessione.
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
      Hai utilizzato qualche forma di aiuto esterno per imparare le connessioni della creatura volante nella Parte 1 o per risolvere il compito nella Parte 2 (per esempio scrivendo le connessioni)?
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
      Before starting, you will have the chance to complete <strong>two example trials</strong> by clicking "Continue."
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
      In yesterday's part of the experiment, you learned that the flying creature moves only between certain pairs of fruits and vegetables. These are the <strong>known connections</strong>.
      </p>
      <p>
      Today, the flying creature needs to move between fruits and vegetables that are <strong>not directly
      connected</strong>. To reach them, it must travel <strong>indirectly</strong> by
      passing through other fruits and vegetables using the <strong>known connections from yesterday</strong>.
      </p>
      <p>
      Each time the flying creature stops at an intermediate item, this counts as a stopover and takes time.
      Your task is therefore to help it find the route with the <strong>fewest stopovers</strong>.
      </p>
      <p>
      In the following, you will carry out this task for the flying creature.
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
    As in the earlier task, you can draw connections by <strong>dragging the cursor</strong> from one fruit or vegetable
    to another. If you want to remove a connection you have already drawn, you can <strong>double-click</strong> on it
    or use the <strong>reset button</strong>, which deletes all previously drawn connections at once.
    </p>
    <p>
    Please make sure that the flying creature can reach every fruit and vegetable through at least one connection.
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
    Did you use any form of external aid to learn the flying creature's connections in Part 1, or to
    solve the task in Part 2 (for example, by writing the connections down)?
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
