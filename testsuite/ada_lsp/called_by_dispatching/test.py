"""test that callHierarchy/incomingCalls works for dispatching calls"""

from drivers.pylsp import (
    URI,
    ALSLanguageClient,
    assertLocationsList,
    test,
)


@test()
async def test_called_by(lsp: ALSLanguageClient):
    # Send a didOpen for main.adb
    main_adb_uri = lsp.didOpenFile("main.adb")
    root_ads_uri = URI("root.ads")

    # Send a textDocument/prepareCallHierarchy request
    result1 = await lsp.prepareCallHierarchy(main_adb_uri, 7, 4)
    assert result1

    # Expect these locations
    assertLocationsList(result1, [("root.ads", 5)])

    # Now send the callHierarchy/incomingCalls request
    result2 = await lsp.callHierarchyIncomingCalls(root_ads_uri, 5, 14)
    assert result2

    # Expect these locations
    assertLocationsList(result2, [("main.adb", 3)])
