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
const firstSetBlockLabelDe = firstSetBlocks === 1 ? "Block" : "Blocke";
const secondSetBlockLabelDe = secondSetBlocks === 1 ? "Block" : "Blocke";

const INSTRUCTION_COPY = {
  it: {
    task1Part1: `
    <h1>Parte I</h1>
    <br>
    <h2>Compito 1</h2>
    <h3>Istruzioni</h3>
    <p>
      In questo compito vedrai diversi alimenti disposti in un ambiente. Il tuo compito è
      <strong>trovare il pipistrello nascosto</strong> cliccando sugli alimenti. Una volta trovato, osserva
      tra quali due alimenti si sposta e ricorda questa connessione.
    </p>
    <p>
      Successivamente, dovrai <strong>disegnare il percorso del pipistrello</strong> cliccando su uno dei due alimenti
      e trascinando il cursore fino all'altro. In questo modo creerai una connessione tra i due elementi. Una linea verde o rossa
      mostrerà se la connessione è corretta oppure no.
    </p>
    <p>
      Potrai passare alla prova successiva solo dopo aver disegnato la connessione corretta oppure dopo più di
      10 tentativi sbagliati.
      La posizione degli alimenti può cambiare di tanto in tanto, ma questo non influisce su quali
      connessioni sono corrette.
    </p>
    <p>
      La direzione del movimento non è importante. Se il pipistrello si sposta tra due alimenti, la stessa
      connessione è corretta in entrambe le direzioni. Allo stesso modo, non importa in quale direzione
      disegni la connessione.
    </p>
    <p>
      Di tanto in tanto, riceverai un punteggio di prestazione basato sulla frequenza con cui la tua prima risposta è stata corretta in una serie di prove.
    </p>
    <p>
      Nel corso dell'intero esperimento, lavorerai con due diversi insiemi di elementi.
    </p>
    <p>
      Prima di iniziare con il primo insieme, completerai <strong>due prove di pratica</strong> cliccando su "Continua".
      Successivamente, completerai ${firstSetBlocks} ${firstSetBlockLabelIt} con il primo insieme di elementi,
      seguiti da ${secondSetBlocks} ${secondSetBlockLabelIt} con il secondo insieme.
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
      Nella parte di ieri dell'esperimento, hai imparato che il pipistrello si sposta solo
      tra alcune coppie di alimenti <strong>collegate tra loro</strong>.
    </p>
    <p>
      Oggi vedrai prima immagini singole di alimenti, presentate una dopo
      l'altra. Ti preghiamo di osservare attentamente ciascuna immagine.
    </p>
    <p>
      A volte, dopo un'immagine singola, appariranno <strong>due immagini</strong>.
      In questi casi, cerca di ricordare l'immagine singola mostrata
      immediatamente prima.
      A differenza di ieri, le due immagini non formeranno una connessione diretta.
    </p>
    <p>
      Il tuo compito è decidere quale dei due elementi può essere raggiunto
      a partire dall'elemento precedente usando <strong>meno connessioni</strong>,
      assumendo il ruolo del pipistrello.
    </p>
    <p>
      Usa i tasti freccia sinistra e destra per rispondere.
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
      In alto vedrai tre immagini di esempio. Cerca di ricordare queste tre connessioni. Al centro dello schermo vedrai prima immagini singole e poi una prova di scelta del percorso.
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
    Questa parte durerà circa un’ora in totale e includerà due pause programmate,
    all’incirca ogni 20 minuti, offrendoti alcune opportunità per riposare.
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
    part3CongrIntro: `
    <h3>Istruzioni</h3>
    <p>
      Nel compito seguente farai quasi <strong>la stessa cosa della
      Parte II</strong>.
    </p>
    <p>
      Solo che questa volta vedrai <strong>quattro elementi</strong> sullo schermo
      contemporaneamente, organizzati come due percorsi tra un elemento iniziale
      e un elemento finale.
    </p>
    <p>
      Come prima, il tuo compito è decidere quale dei due percorsi
      richiede <strong>meno connessioni</strong>, assumendo di nuovo
      il ruolo del pipistrello.
    </p>
    <p>
      Prenditi il tempo necessario e fai clic su "Continua" per iniziare.
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
  de: {
    task1Part1: `
    <h1>Teil I</h1>
    <br>
    <h2>Aufgabe 1</h2>
    <h3>Anweisungen</h3>
    <p>
      In dieser Aufgabe siehst du mehrere Lebensmittel, die in einer Umgebung angeordnet sind. Deine Aufgabe ist es,
      <strong>die versteckte Fledermaus zu finden</strong>, indem du auf die Lebensmittel klickst. Sobald du sie gefunden hast, achte darauf,
      zwischen welchen zwei Lebensmitteln sie sich bewegt, und merke dir diese Verbindung.
    </p>
    <p>
      Anschließend wirst du <strong>den Weg der Fledermaus einzeichnen</strong>, indem du auf eines der beiden Lebensmittel klickst
      und den Cursor zum anderen ziehst. So erzeugst du eine Verbindung zwischen den beiden Elementen. Eine grune oder rote Linie
      zeigt dir, ob die Verbindung richtig ist oder nicht.
    </p>
    <p>
      Du kannst erst dann mit dem nachsten Durchgang fortfahren, wenn du die richtige Verbindung eingezeichnet hast oder mehr als
      10 falsche Versuche gemacht hast.
      Die Positionen der Lebensmittel konnen sich von Zeit zu Zeit andern, aber das beeinflusst nicht,
      welche Verbindungen richtig sind.
    </p>
    <p>
      Die Bewegungsrichtung ist nicht wichtig. Wenn sich die Fledermaus zwischen zwei Lebensmitteln bewegt, ist dieselbe
      Verbindung in beide Richtungen richtig. Ebenso spielt es keine Rolle, in welche Richtung du
      die Verbindung zeichnest.
    </p>
    <p>
      Von Zeit zu Zeit erhaltst du eine Leistungsruckmeldung, die darauf basiert, wie oft deine erste Antwort in einer Reihe von Durchgangen richtig war.
    </p>
    <p>
      Im Verlauf des gesamten Experiments arbeitest du mit zwei verschiedenen Satzen von Elementen.
    </p>
    <p>
      Bevor du mit dem ersten Satz beginnst, absolvierst du <strong>zwei Ubungsdurchgange</strong>, indem du auf "Weiter" klickst.
      Danach bearbeitest du ${firstSetBlocks} ${firstSetBlockLabelDe} mit dem ersten Satz von Elementen,
      gefolgt von ${secondSetBlocks} ${secondSetBlockLabelDe} mit dem zweiten Satz.
    </p>
  `,
    task1Part1End: `
    <h3>Bist du bereit?</h3>
    <br>
    <p>
      Die Ubungsphase ist nun beendet. Wie bereits erklart, besteht deine Aufgabe darin, dir zu merken, wo die Fledermaus in jedem Durchgang gestartet ist und wo sie geendet hat.
    </p>
    <p>
      Wenn du bereit bist, klicke auf die Schaltflache "Weiter", um das Experiment zu beginnen.
    </p>
  `,
    task1SetTransition: `
    <p>Du hast den ersten Satz von Elementen abgeschlossen.</p>
    <p>Wenn du mogst, kannst du eine kurze Pause machen.</p>
    <p>Wenn du auf "Weiter" klickst, beginnt der zweite Satz von Elementen.</p>
  `,
    task2Part1: `
    <h2>Aufgabe 2</h2>
    <h3>Anweisungen</h3>
    <p>
      Hast du bemerkt, dass sich die Fledermaus nur zwischen bestimmten Paaren von Lebensmitteln bewegt hat?
    </p>
    <p>
      Diese Paare nennen wir <strong>Verbindungen</strong>. Vielleicht ist dir auch aufgefallen, dass sich die Fledermaus immer gleich gut in beide Richtungen bewegen konnte, wenn sie einer Verbindung folgte. Das bedeutet, dass die Richtung keine Rolle spielt.
    </p>
    <p>
      Im Folgenden siehst du mehrere Paare von Lebensmitteln. Versuche dich aus der vorherigen Aufgabe daran zu erinnern,
      <strong>ob zwischen den beiden gezeigten Elementen eine Verbindung bestand oder nicht</strong>. Gib deine Antwort
      durch Klicken auf eine der Schaltflachen an.
    </p>
    <p>
      Dieses Mal gibt es keinen Ubungsdurchgang, du kannst also direkt beginnen.
    </p>
  `,
    part2Intro: `
    <h1>Teil II</h1>
    <br>
    <h3>Anweisungen</h3>
    <p>
      Im gestrigen Teil des Experiments hast du gelernt, dass sich die Fledermaus nur
      zwischen bestimmten <strong>miteinander verbundenen Paaren</strong> von Lebensmitteln bewegt.
    </p>
    <p>
      Heute siehst du zunachst einzelne Bilder von Lebensmitteln, die nacheinander prasentiert werden.
      Bitte achte genau auf jedes Bild.
    </p>
    <p>
      Manchmal erscheinen nach einem einzelnen Bild <strong>zwei Bilder</strong>.
      In diesen Fallen versuche dich bitte an das einzelne Bild zu erinnern, das
      unmittelbar davor gezeigt wurde.
      Anders als gestern bilden die beiden Bilder keine direkte Verbindung.
    </p>
    <p>
      Deine Aufgabe ist es zu entscheiden, welches der beiden Elemente vom
      vorherigen Element aus mit <strong>weniger Verbindungen</strong> erreicht werden kann,
      wenn du die Rolle der Fledermaus ubernimmst.
    </p>
    <p>
      Benutze zum Antworten die linke und rechte Pfeiltaste.
    </p>
    <p>
      Drucke jetzt die rechte Pfeiltaste, und wir zeigen dir eine kurze Demonstration.
    </p>
  `,
    part2Demo: `
    <h3>Demonstration</h3>
    <p>
      Dies ist nur eine <strong>Demonstration</strong> und gehort <strong>nicht</strong> zur eigentlichen Aufgabe.
    </p>
    <p>
      Oben siehst du drei Beispielbilder. Versuche dir diese drei Verbindungen zu merken. In der Mitte des Bildschirms siehst du zuerst einzelne Bilder und danach einen Test zur Routenwahl.
    </p>
    <p>
      Nach der Demonstration kannst du sie so oft wiederholen, wie du mochtest, oder mit der eigentlichen Aufgabe fortfahren.
    </p>
  `,
    part2Start: `
    <h3>Beginn des Experiments</h3>
    <p>
      Gut. Du hast jetzt gelernt, wie die Aufgabe funktioniert.
    </p>
    <p>
      Wenn du die rechte Pfeiltaste druckst, beginnt das eigentliche Experiment.
    </p>
    <p>
    Dieser Teil dauert insgesamt etwa eine Stunde und enthalt zwei geplante Pausen,
    ungefahr alle 20 Minuten, sodass du dich kurz erholen kannst.
    </p>
  `,
    part3First: `
    <h2>Teil III</h2>
    <h3>Anweisungen</h3>
    <br>
    <p>
      Im nachsten Teil des Experiments bitten wir dich, <strong>die Lebensmittel in der Umgebung anzuordnen</strong>, und zwar auf eine Weise, die dir sinnvoll erscheint.
    </p>
    <p>
      Zu Beginn erscheinen die Lebensmittel auf der rechten Seite. Um eines davon in der Umgebung zu platzieren, klicke darauf und ziehe es an die Position, die dir am passendsten erscheint. Du kannst die Anordnung so oft andern, wie du mochtest, indem du die Elemente erneut verschiebst.
    </p>
    <p>
      Fur diesen Teil gibt es keinen Ubungsdurchgang. Nimm dir so viel Zeit, wie du brauchst.
    </p>
    <p>
      Nachdem du auf "Weiter" geklickt hast, beginnt der nachste Durchgang mit dem ersten Satz von Elementen.
    </p>
    <br>
  `,
    part3Second: `
    <h3>Anweisungen</h3>
    <p>
      Anschließend zeigen wir dir die Umgebung mit den Lebensmitteln so, wie du sie zuvor angeordnet hast. Dieses Mal bitten wir dich, <strong>die Verbindungen</strong> so einzuzeichnen, wie du sie in Erinnerung hast.
    </p>
    <p>Wie in der gestrigen Aufgabe kannst du Verbindungen <strong>einzeichnen, indem du den Cursor ziehst</strong> von einem Lebensmittel
    zum anderen. Wenn du eine Verbindung entfernen mochtest, die du bereits eingezeichnet hast, kannst du
    darauf <strong>doppelklicken</strong> oder die <strong>Reset-Schaltflache</strong> verwenden, mit der
    alle eingezeichneten Verbindungen auf einmal geloscht werden.
    </p>
    <p>
      Achte darauf, dass die Fledermaus jedes Lebensmittel uber mindestens eine Verbindung erreichen kann.
    </p>
    <p>
      Es gibt kein Zeitlimit. Nimm dir so viel Zeit, wie du brauchst, und klicke auf "Weiter", wenn du fertig bist.
    </p>
    <br>
  `,
    part3CongrIntro: `
    <h3>Anweisungen</h3>
    <p>
      In der folgenden Aufgabe wirst du fast <strong>dasselbe wie in
      Teil II</strong> tun.
    </p>
    <p>
      Dieses Mal siehst du jedoch <strong>vier Elemente</strong> gleichzeitig auf dem Bildschirm,
      angeordnet als zwei Routen zwischen einem Start- und einem Endelement.
    </p>
    <p>
      Wie zuvor ist es deine Aufgabe zu entscheiden, welche der beiden Routen
      <strong>weniger Verbindungen</strong> erfordert, wahrend du wieder
      die Rolle der Fledermaus ubernimmst.
    </p>
    <p>
      Nimm dir so viel Zeit, wie du brauchst, und klicke auf "Weiter", um zu beginnen.
    </p>
    <br>
  `,
    cheater: `
    <h3>Herzlichen Gluckwunsch, du bist fast fertig. Eine allerletzte Frage:</h3>
    <br>
    <p>
    Hast du irgendeine Form externer Hilfe verwendet, um die Verbindungen der Fledermaus in Teil I zu lernen
    oder um die Aufgaben in Teil II oder III zu losen (zum Beispiel, indem du die Verbindungen aufgeschrieben hast)?
    </p>
    <p>
      (Bitte antworte ehrlich. Deine Antwort auf diese Frage hat keinerlei Einfluss auf deine Vergutung.)
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
    In this task, you will see several food items arranged in an environment. Your task is to
    <strong>find the hidden bat</strong> by clicking on the items. Once you find it, watch
    which two items it moves between and remember this connection.
    </p>
    <p>
    Next, you will <strong>draw the bat's path</strong> by clicking on one of the two items and
    dragging the cursor to the other. This creates a connection between them. A green or red
    line will show whether the connection is correct or not.
    </p>
    <p>
    You can continue to the next trial only after drawing the correct connection or after more than
    10 incorrect attempts.
    The positions of the food items may change from time to time, but this does not affect which
    connections are correct.
    </p>
    <p>
    The direction of movement does not matter. If the bat moves between two items, the same
    connection is correct in both directions. Relatedly, the direction in which you draw
    the connection also does not matter.
    </p>
    <p>
    From time to time, you will receive a performance score based on your first-attempt accuracy across several trials.
    </p>
    <p>
    Over the full experiment, you will work with two different sets of items.
    </p>
    <p>
    Before starting the first set, you will complete <strong>two practice trials</strong> by clicking "Continue."
    Afterward, you will complete ${firstSetBlocks} ${firstSetBlockLabelEn} with the first set of items,
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
    In yesterday's part of the experiment, you learned that the bat moved only
    between certain, <strong>connected pairs</strong> of food items.
    </p>
    <p>
    Today, you will first see single images of food items, presented one after
    another. Please pay close attention to each image.
    </p>
    <p>
    Occasionally, <strong>two images</strong> will appear after a single image.
    In those cases, please remember the single image shown immediately
    before.
    Unlike yesterday, the two images will not form a direct connection. 
    </p>
    <p>
    Your task is to decide which of the two items can be reached from the
    previous item using <strong>fewer connections</strong>, while taking
    the role of the bat.
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
    Imagine that, yesterday, you learned these three connections. Please try to remember them for the demo that follows.
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
    This part will take about one hour in total and will include two scheduled breaks,
    roughly every 20 minutes, giving you opportunities to rest.
    </p>
    `,
    part3First: `
    <h2>Part III</h2>
    <h3>Instructions</h3>
    <br>
    <p>
    In this task of the experiment, we ask you to <strong>arrange the food items in the environment</strong>
    in a way that seems reasonable to you.
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
    part3CongrIntro: `
    <h3>Instructions</h3>
    <p>
    In the following task, you will do nearly <strong>the same task as in
    Part II</strong>.
    </p>
    <p>
    Only this time, you will see <strong>four items</strong> on the screen
    simultanously, arranged as two routes between a start item and an end item.
    </p>
    <p>
    Similar to before, your task is to decide which of the two routes
    requires <strong>fewer connection</strong>, while
    taking the role of the bat.
    </p>
    <p>
    Take as much time as you need, and click "Continue" to begin.
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
