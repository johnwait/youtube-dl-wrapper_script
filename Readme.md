Une _[version française](#franzosisch) du présent document est disponible plus bas._

# _youtube-dl_ Wrapper Script for Windows

> A Hybrid batch-JScript.NET script, localized for both **French** and **English**, to make using the [_youtube-dl_ Utility](https://ytdl-org.github.io/youtube-dl/index.html) a (slightly) more user-friendly experience.

#### Features

- Localized
- Supports YouTube URLs as well as any other URL generically supported by [_youtube-dl_](https://ytdl-org.github.io/youtube-dl/index.html)
- Handles video format parsing, allowing video / audio streams merging **†** or standalone download
- Prompts for the location and filename of the downloaded video file using a Save-As dialog

_**†** Require the availability of a second utility, [ffmpeg](https://ffmpeg.org)_

#### Requirements

1. A Windows computer with the .NET Framework installed or integrated;
2. A local copy of the [_youtube-dl_](https://ytdl-org.github.io/youtube-dl/index.html) utility;
3. Optionally (but recommended), a local install/build of [_ffmpeg_](https://ffmpeg.org);
4. The script this Readme document is for, i.e. `youtube-dl_run.cmd`.

#### How to use

1. Download locally the latest version of the [_youtube-dl_ command line utility](https://ytdl-org.github.io/youtube-dl/download.html), which comes as a single, no-install executable.
   Also, unless your computer is fairly recent or that it already has the runtimes installed, you might also have to download and install the [Microsoft Visual C++ 2010 Redistributable Package (x86, KB2565063 Update)](http://www.microsoft.com/en-us/download/details.aspx?id=26999)
2. Download the [latest copy of the `youtuve-dl_run.cmd` script](https://github.com/johnwait/youtube-dl_wrapper_script/blob/master/youtube-dl_run.cmd). Ideally, put it in the same folder the for the _youtube-dl_ utility; otherwise you'll have to **edit the script** to specify the path to the _youtube-dl.exe_ binary (environment variable: `l_ytdl_dir`)
3. If you want to be able you select individual video-only and audio-only streams and then have then merged once downloaded (for example, if the video stream you want is only available without an audio track), you'll need:
   - a local copy of the [_ffmpeg_ utility](https://ffmpeg.org), which you can [download here](https://ffmpeg.org/download.html#build-windows);
   - once/if already installed, to **edit the script** to specify the path to the _ffmpeg.exe_ executable (environment variable: `l_ffmpeg_path`).

You're then ready to use the script to download for offline use a YouTube video, like [a play in French based on the 1957 film _12 Angry Men_](https://www.youtube.com/watch?v=B5EwCHMGIz8)

#### License

The file `youtube-dl_run.cmd` is provided through a MIT-style license:

```
Copyright © 2019 Jonathan Richard-Brochu and other contributors.

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

1. The above copyright notice and this permission notice shall be included 
   in all copies or substantial portions of the Software.

2. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
   OTHER DEALINGS IN THE SOFTWARE.
```

### *WARNING*

You should neither trust nor blindly execute machine code, whether compiled, interpreted, available as a script even when such code it is available to you as source code, including open source software; always ensure the code has either been reviewed or can easily be reviewed, that you understand what it is and what is does, and **in doubt refrain from executing** unknown, obscure, untrustworthy, or in general any piece of code that you haven't written yourself when cannot be sure of its actions after having reviewed the code yourself or having it reviewed by a trustworthy and knowledgeable person.

---

<a name="franzosisch"></a>
# Script—enveloppe pour l'utilitaire _youtube-dl_ pour Windows

> Un script hybride (_batch_—JScript.NET) ayant pour objectif de faciliter l'utilisation du gratuiciel [_youtube-dl_ (*attention : site en anglais)](https://ytdl-org.github.io/youtube-dl/index.html).

#### Fonctionnalités et avantages

- S'adapte à la langue d'affichage du système d'exploitation
- Prends en charge tout lien accepté par [_youtube-dl_](https://ytdl-org.github.io/youtube-dl/index.html)
- Simplifie la sélection du format vidéo, et permets la fusion **†** de flux audio / vidéo ou encore leur téléchargement individuel
- Permets la spécification de l'emplacement et du nom de fichier de la vidéo à télécharger via une boîte de dialogue « Enregistrer sous »

_**†** Requiert la disponibilité d'un second utilitaire, [ffmpeg (*site en anglais)](https://ffmpeg.org)_

#### Exigences techniques

1. Un ordinateur Windows avec le composant .NET Framework installé ou intégré ;
2. Un exemplaire local de l'utilitaire [_youtube-dl_](https://ytdl-org.github.io/youtube-dl/index.html) ;
3. Facultativement (mais fortement recommandé), une installation / compilation locale de [_ffmpeg_](https://ffmpeg.org) ;
4. Le script auquel ce document « Lisez-moi » est fait référence, c'est-à-dire `youtube-dl_run.cmd`.

#### Consignes d'utilisation

1. Téléchargez localement la dernière version de l'[utilitaire de ligne de commande _youtube-dl_](https://ytdl-org.github.io/youtube-dl/download.html), offert sous forme d'exécutable sans besoin d'installation. De même, à moins que votre ordinateur ne soit assez récent ou que ce qui suit soit déjà installé, vous devrez peut-être télécharger et installer le composant distribuable [Microsoft Visual C ++ 2010 (x86, mise à jour KB2565063)](http://www.microsoft.com/en-us/download/details.aspx?id=26999).
2. Téléchargez la [dernière version du script `youtuve-dl_run.cmd`](https://github.com/johnwait/youtube-dl_wrapper_script/blob/master/youtube-dl_run.cmd). Idéalement, placez-le dans le même dossier que pour l'utilitaire _youtube-dl_ ; sinon, vous devrez **éditer le script** pour spécifier le chemin d'accès au fichier binaire _youtube-dl.exe_ (variable d'environnement: `l_ytdl_dir`)
3. Si vous souhaitez pouvoir sélectionner des flux individuels uniquement vidéo et audio pour ensuite les fusionner une fois téléchargés (par exemple, si la résolution souhaitée est uniquement offerte en flux vidéo-seulement), vous aurez besoin des éléments suivants:
   - un exemplaire de [l'utilitaire _ffmpeg_](https://ffmpeg.org), que vous pouvez [télécharger ici](https://ffmpeg.org/download.html#build-windows) ;
   - une fois / si déjà installé, **éditer le script** pour spécifier le chemin de l'exécutable _ffmpeg.exe_ (variable d'environnement: `l_ffmpeg_path`).

Vous êtes maintenant prêt.e à utiliser le script pour télécharger une vidéo YouTube en vue d'une utilisation hors ligne, par exemple [la captation d'une pièce de théâtre en français basée sur le film de 1957 _12 Angry Men_](https://www.youtube.com/watch?v=B5EwCHMGIz8).

#### Licence

Le fichier `youtube-dl_run.cmd` est fourni sous une licence de style « MIT » ; voici une adaptation en français de la licence :

```
Copyright © 2019 Jonathan Richard-Brochu et autres contributeurs.

Par la présente, une autorisation est accordée, gratuitement, à toute 
personne obtenant un exemplaire de ce logiciel et des fichiers de 
documentation associés  (le "Logiciel") d'utiliser le Logiciel sans 
restriction, y compris, sans s'y limiter, le droit d'utiliser, de copier, 
modifier, fusionner, publier, distribuer, accorder une sous-licence et / ou 
vendre des exemplaires ou copies du Logiciel, et il est autorisé aux 
personnes auxquelles le Logiciel est fourni de le faire, sous réserve des 
conditions suivantes :

1. L'avis de copyright ci-dessus et cet avis d'autorisation doivent être 
inclus dans tous les exemplaires, copies ou parties importantes du Logiciel.

2. LE LOGICIEL EST FOURNI "TEL QUEL", SANS GARANTIE D'AUCUNE SORTE, 
   EXPRESSE OU IMPLICITE, Y COMPRIS, MAIS SANS S'Y LIMITER, LES GARANTIES 
   DE QUALITÉ MARCHANDE, D'ADÉQUATION À UN USAGE PARTICULIER ET DE 
   NON-CONTREFAÇON. EN AUCUN CAS LES AUTEURS OU LES DÉTENTEURS DES DROITS 
   D'AUTEUR NE SAURAIENT ÊTRE TENUS RESPONSABLES DE TOUTE RÉCLAMATION, 
   TOUT DOMMAGE OU AUTRE RESPONSABILITÉ, QUE CE SOIT DANS LE CADRE D'UNE 
   ACTION CONTRACTUELLE, DÉLICTUELLE OU AUTRE, DÉCOULANT DE OU EN RAPPORT 
   AVEC LE LOGICIEL OU SON UTILISATION OU D'AUTRES DÉFAUTS DU LOGICIEL.
```

### *Mise en garde*

Vous ne devez ni faire confiance ni exécuter aveuglément un code machine, qu'il soit compilé, interprété, sous forme de script ou même lorsqu'offert sous forme de code source, y compris en source ouverte ; assurez-vous toujours que le code a été révisé ou peut être facilement révisé, que vous comprenez en quoi il consiste et ce qu'il fait et, en cas de doute, **évitez d'exécuter** un code inconnu, obscur, indigne de confiance ou, en général, tout morceau de code que vous n'avez pas écrit vous-même lorsque vous ne pouvez pas être sûr de ses actions après avoir revu le code vous-même ou l'avoir fait relire par une personne de confiance et bien informée.
