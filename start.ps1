$param1 = $args[0]
if ($param1)
{
    $env = $param1
}
else
{
    $env = "development"
}

hugo serve --disableFastRender --buildFuture --buildExpired --buildDrafts --navigateToChanged --environment=$env