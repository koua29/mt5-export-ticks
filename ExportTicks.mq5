//+------------------------------------------------------------------+
//|  ExportTicks.mq5 — Export COMPLET des ticks vers CSV             |
//|                                                                  |
//|  Contourne la limite 131072 du visualiseur MT5 : utilise        |
//|  CopyTicksRange() jour par jour et écrit tout dans un CSV.       |
//|                                                                  |
//|  Installation : copier dans MQL5/Scripts, compiler (F7),        |
//|  puis glisser le script sur un graphe GOLD.                     |
//|  Sortie : <MQL5>/Files/<nom>  (Fichiers → ouvrir dossier data)  |
//|  Format compatible replay_ai_decisions.py :                     |
//|     <DATE>\t<TIME>\t<BID>\t<ASK>                                |
//+------------------------------------------------------------------+
#property script_show_inputs
#property strict

input datetime InpFrom     = D'2026.06.07 00:00:00';   // Début (inclus)
input datetime InpTo       = D'2026.06.19 00:00:00';   // Fin (exclus)
input string   InpFileName = "GOLD_ticks_full.csv";    // Fichier de sortie

void OnStart()
{
   int fh = FileOpen(InpFileName, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(fh == INVALID_HANDLE)
   {
      PrintFormat("❌ Impossible d'ouvrir %s (err %d)", InpFileName, GetLastError());
      return;
   }
   FileWriteString(fh, "<DATE>\t<TIME>\t<BID>\t<ASK>\r\n");

   ulong total = 0;
   // Découpage jour par jour : robuste mémoire + aucun plafond
   for(datetime day = InpFrom; day < InpTo; day += 86400)
   {
      datetime day_end = day + 86400;
      if(day_end > InpTo) day_end = InpTo;

      MqlTick ticks[];
      ulong from_msc = (ulong)day     * 1000;
      ulong to_msc   = (ulong)day_end * 1000 - 1;
      int n = CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL, from_msc, to_msc);
      if(n <= 0) continue;

      for(int i = 0; i < n; i++)
      {
         datetime t = ticks[i].time;
         int      ms = (int)(ticks[i].time_msc % 1000);
         string line = TimeToString(t, TIME_DATE) + "\t"
                     + TimeToString(t, TIME_SECONDS) + "."
                     + StringFormat("%03d", ms) + "\t"
                     + DoubleToString(ticks[i].bid, _Digits) + "\t"
                     + DoubleToString(ticks[i].ask, _Digits) + "\r\n";
         FileWriteString(fh, line);
      }
      total += (ulong)n;
      PrintFormat("📅 %s : %d ticks (cumul %I64u)", TimeToString(day, TIME_DATE), n, total);
   }

   FileClose(fh);
   PrintFormat("✅ Export terminé : %I64u ticks → MQL5/Files/%s", total, InpFileName);
}
//+------------------------------------------------------------------+
