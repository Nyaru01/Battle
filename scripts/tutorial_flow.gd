class_name BattleTutorial
extends RefCounted

enum Step {
	SELECT_GUARDIAN,
	DEPLOY_GUARDIAN_LEFT,
	SELECT_RANGER,
	DEPLOY_RANGER_RIGHT,
	COMPLETE,
}

var step := Step.SELECT_GUARDIAN


func reset() -> void:
	step = Step.SELECT_GUARDIAN


func can_select(card_id: String) -> bool:
	return (step == Step.SELECT_GUARDIAN and card_id == "guardian") or (step == Step.SELECT_RANGER and card_id == "ranger")


func select_card(card_id: String) -> bool:
	if not can_select(card_id):
		return false
	step = Step.DEPLOY_GUARDIAN_LEFT if card_id == "guardian" else Step.DEPLOY_RANGER_RIGHT
	return true


func can_deploy(card_id: String, lane: int) -> bool:
	return (step == Step.DEPLOY_GUARDIAN_LEFT and card_id == "guardian" and lane == 0) or (step == Step.DEPLOY_RANGER_RIGHT and card_id == "ranger" and lane == 1)


func deploy_card(card_id: String, lane: int) -> bool:
	if not can_deploy(card_id, lane):
		return false
	step = Step.SELECT_RANGER if card_id == "guardian" else Step.COMPLETE
	return true


func is_complete() -> bool:
	return step == Step.COMPLETE


func instruction() -> String:
	match step:
		Step.SELECT_GUARDIAN:
			return "1/4  Sélectionne la carte Gardien"
		Step.DEPLOY_GUARDIAN_LEFT:
			return "2/4  Touche la voie de gauche pour déployer le Gardien"
		Step.SELECT_RANGER:
			return "3/4  Sélectionne maintenant l’Éclaireuse"
		Step.DEPLOY_RANGER_RIGHT:
			return "4/4  Déploie l’Éclaireuse sur la voie de droite"
		_:
			return "Tutoriel terminé • l’IA entre dans l’arène"
