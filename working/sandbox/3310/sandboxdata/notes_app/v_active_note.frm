TYPE=VIEW
query=select `n`.`id` AS `note_id`,`n`.`title` AS `title`,`n`.`body` AS `body`,`n`.`is_pinned` AS `is_pinned`,`n`.`created_at` AS `created_at`,`n`.`updated_at` AS `updated_at`,`nb`.`id` AS `notebook_id`,`nb`.`name` AS `notebook_name`,`a`.`id` AS `account_id`,`a`.`email` AS `account_email`,group_concat(distinct `t`.`name` order by `t`.`name` ASC separator \',\') AS `tags` from ((((`notes_app`.`note` `n` join `notes_app`.`notebook` `nb` on(`nb`.`id` = `n`.`notebook_id`)) join `notes_app`.`account` `a` on(`a`.`id` = `n`.`account_id`)) left join `notes_app`.`note_tag` `nt` on(`nt`.`note_id` = `n`.`id`)) left join `notes_app`.`tag` `t` on(`t`.`id` = `nt`.`tag_id`)) where `n`.`status` = \'active\' group by `n`.`id`,`n`.`title`,`n`.`body`,`n`.`is_pinned`,`n`.`created_at`,`n`.`updated_at`,`nb`.`id`,`nb`.`name`,`a`.`id`,`a`.`email`
md5=7899e2daebb49fec4ff81d39b2c726a6
updatable=0
algorithm=0
definer_user=root
definer_host=localhost
suid=2
with_check_option=0
timestamp=0001790360171382743
create-version=2
source=SELECT\n  n.id          AS note_id,\n  n.title       AS title,\n  n.body        AS body,\n  n.is_pinned   AS is_pinned,\n  n.created_at  AS created_at,\n  n.updated_at  AS updated_at,\n  nb.id         AS notebook_id,\n  nb.name       AS notebook_name,\n  a.id          AS account_id,\n  a.email       AS account_email,\n  GROUP_CONCAT(DISTINCT t.name ORDER BY t.name SEPARATOR \',\') AS tags\nFROM notes_app.note n\nJOIN notes_app.notebook nb ON nb.id = n.notebook_id\nJOIN notes_app.account a   ON a.id = n.account_id\nLEFT JOIN notes_app.note_tag nt ON nt.note_id = n.id\nLEFT JOIN notes_app.tag t        ON t.id = nt.tag_id\nWHERE n.status = \'active\'\nGROUP BY\n  n.id, n.title, n.body, n.is_pinned, n.created_at, n.updated_at,\n  nb.id, nb.name, a.id, a.email
client_cs_name=utf8mb4
connection_cl_name=utf8mb4_uca1400_ai_ci
view_body_utf8=select `n`.`id` AS `note_id`,`n`.`title` AS `title`,`n`.`body` AS `body`,`n`.`is_pinned` AS `is_pinned`,`n`.`created_at` AS `created_at`,`n`.`updated_at` AS `updated_at`,`nb`.`id` AS `notebook_id`,`nb`.`name` AS `notebook_name`,`a`.`id` AS `account_id`,`a`.`email` AS `account_email`,group_concat(distinct `t`.`name` order by `t`.`name` ASC separator \',\') AS `tags` from ((((`notes_app`.`note` `n` join `notes_app`.`notebook` `nb` on(`nb`.`id` = `n`.`notebook_id`)) join `notes_app`.`account` `a` on(`a`.`id` = `n`.`account_id`)) left join `notes_app`.`note_tag` `nt` on(`nt`.`note_id` = `n`.`id`)) left join `notes_app`.`tag` `t` on(`t`.`id` = `nt`.`tag_id`)) where `n`.`status` = \'active\' group by `n`.`id`,`n`.`title`,`n`.`body`,`n`.`is_pinned`,`n`.`created_at`,`n`.`updated_at`,`nb`.`id`,`nb`.`name`,`a`.`id`,`a`.`email`
mariadb-version=110809
