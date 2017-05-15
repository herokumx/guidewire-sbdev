trigger CaseEscalator on Case (before update)
{
    CaseEscalatorHandler CEH = new CaseEscalatorHandler();
    CEH.Escalator(trigger.oldMap, trigger.new);
}