import { useAccountToken } from "@avalsys/account-av-web";
import { useMemo } from "react";
import { AnimateApiClient } from "@/lib/animate-api-client";

export function useAnimateApiClient() {
  const getToken = useAccountToken();
  return useMemo(() => new AnimateApiClient({ getToken }), [getToken]);
}
