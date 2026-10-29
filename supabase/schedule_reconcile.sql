-- Schedule reconcile-orders every minute.
--
-- Why: checkout reserves stock as soon as a PENDING order is created. If the
-- customer abandons payment, only reconcile-orders expires the invoice and
-- restores the reserved stock. Without this schedule, repeated abandoned
-- checkouts can drain the catalog to zero.
--
-- Prerequisites:
--   1. reconcile-orders is deployed.
--   2. RECONCILE_SECRET is set for the Edge Functions.
--   3. Run this file in the Supabase SQL Editor as postgres.
--
-- Set the same RECONCILE_SECRET value in Vault below. Never commit the real
-- value to this file or to Flutter code.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net;

do $$
declare
  secret_value text := 'REPLACE_WITH_RECONCILE_SECRET';
  sid uuid;
begin
  if secret_value = 'REPLACE_WITH_RECONCILE_SECRET' then
    raise exception 'Replace REPLACE_WITH_RECONCILE_SECRET with the real RECONCILE_SECRET before running this file';
  end if;
  select id into sid from vault.secrets where name = 'reconcile_secret';
  if sid is null then
    perform vault.create_secret(
      secret_value,
      'reconcile_secret',
      'Bearer secret for scheduled reconcile-orders calls'
    );
  else
    perform vault.update_secret(sid, secret_value);
  end if;
end $$;

-- Replace an existing job with the same name, so this file is safe to re-run.
select cron.unschedule(jobid)
from cron.job
where jobname = 'jj-reconcile-orders';

select cron.schedule(
  'jj-reconcile-orders',
  '* * * * *',
  $job$
  select net.http_post(
    url := 'https://bnomvznpwasejddetmte.supabase.co/functions/v1/reconcile-orders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce(
        (select decrypted_secret from vault.decrypted_secrets where name = 'reconcile_secret'),
        ''
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $job$
);

-- Verify the job and recent runs.
select jobid, jobname, schedule, active, username from cron.job;
select jobid, status, return_message, start_time
from cron.job_run_details
order by start_time desc
limit 5;
