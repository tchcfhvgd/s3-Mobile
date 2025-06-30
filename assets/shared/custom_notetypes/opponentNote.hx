package assets.shared.custom_notetypes;

function opponentNoteHitPre(note)
{
	if (note.noteType == 'opponentNote')
	{
		note.gfNote = false;
	}
}
